import os
import re

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="DBCopilot AI Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3")

# Default schema shown to the LLM so it generates accurate SQL.
# The Spring Boot backend can send a custom schema via the request body.
DEFAULT_SCHEMA = """
Table: customers
  Columns: customer_id (SERIAL PK), customer_name (VARCHAR), city (VARCHAR), status (VARCHAR: ACTIVE/INACTIVE), email (VARCHAR), phone (VARCHAR), created_at (TIMESTAMP)

Table: employees
  Columns: employee_id (SERIAL PK), employee_name (VARCHAR), department (VARCHAR), salary (NUMERIC), joining_date (DATE), status (VARCHAR: ACTIVE/INACTIVE)

Table: orders
  Columns: order_id (SERIAL PK), customer_id (INT FK→customers), product_id (INT FK→products), amount (NUMERIC), order_date (DATE), status (VARCHAR: PENDING/COMPLETED/CANCELLED)

Table: products
  Columns: product_id (SERIAL PK), product_name (VARCHAR), category (VARCHAR), price (NUMERIC), stock (INT)
"""


class GenerateSqlRequest(BaseModel):
    query: str
    schema: str | None = None


class GenerateSqlResponse(BaseModel):
    sql: str
    explanation: str


def build_prompt(query: str, schema: str) -> str:
    return f"""You are a PostgreSQL SQL expert. Convert natural language to a valid PostgreSQL SELECT query.

STRICT RULES:
1. Output ONLY the raw SQL query — no markdown, no code blocks, no explanation text.
2. Only generate SELECT queries. Never use DELETE, UPDATE, INSERT, DROP, ALTER, or TRUNCATE.
3. Always add LIMIT 100 unless the user asks for a specific number.
4. Use exact column and table names from the schema below.
5. If the query is ambiguous, make a reasonable assumption.

Database Schema:
{schema}

Natural language query: "{query}"

SQL:"""


def extract_sql(raw: str) -> str:
    # Strip markdown code fences
    raw = re.sub(r"```sql\s*", "", raw, flags=re.IGNORECASE)
    raw = re.sub(r"```\s*", "", raw)
    raw = raw.strip()

    # Pull out the first SELECT statement
    match = re.search(r"(SELECT\b.+?)(?:;|$)", raw, re.IGNORECASE | re.DOTALL)
    if match:
        sql = match.group(1).strip()
        return sql + ";" if not sql.endswith(";") else sql

    # Fallback: return whatever came back
    return raw


async def call_ollama(prompt: str) -> str:
    async with httpx.AsyncClient(timeout=120.0) as client:
        response = await client.post(
            f"{OLLAMA_URL}/api/generate",
            json={"model": OLLAMA_MODEL, "prompt": prompt, "stream": False},
        )
        response.raise_for_status()
        return response.json().get("response", "").strip()


@app.get("/")
def root():
    return {"message": "DBCopilot AI Service", "status": "ok", "model": OLLAMA_MODEL}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.post("/generate-sql", response_model=GenerateSqlResponse)
async def generate_sql(request: GenerateSqlRequest):
    if not request.query or not request.query.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    schema = request.schema or DEFAULT_SCHEMA
    prompt = build_prompt(request.query.strip(), schema)

    try:
        raw_response = await call_ollama(prompt)
        sql = extract_sql(raw_response)

        if not sql.upper().startswith("SELECT"):
            raise HTTPException(
                status_code=422,
                detail=f"AI did not generate a SELECT query. Got: {sql[:100]}",
            )

        explanation = f"Converted '{request.query}' into a SQL query."
        return GenerateSqlResponse(sql=sql, explanation=explanation)

    except httpx.ConnectError:
        raise HTTPException(
            status_code=503,
            detail="Cannot connect to Ollama. Make sure Ollama is running: `ollama serve`",
        )
    except httpx.TimeoutException:
        raise HTTPException(
            status_code=504,
            detail="Ollama took too long to respond. Try a smaller model like phi3.",
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI generation error: {str(e)}")


@app.post("/explain-sql")
async def explain_sql(body: dict):
    sql = body.get("sql", "")
    if not sql:
        raise HTTPException(status_code=400, detail="sql field is required")

    prompt = f"""Explain this PostgreSQL query in plain English for a non-technical user.
Keep it to 1-2 sentences.

SQL: {sql}

Explanation:"""

    try:
        explanation = await call_ollama(prompt)
        return {"explanation": explanation.strip()}
    except Exception:
        return {"explanation": "Query executed successfully."}
