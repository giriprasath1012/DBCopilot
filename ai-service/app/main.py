import os
import re
from collections import defaultdict

import httpx
import psycopg2
import psycopg2.extras
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

OLLAMA_URL   = os.getenv("OLLAMA_URL",   "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3")

DB_HOST     = os.getenv("DB_HOST",     "localhost")
DB_NAME     = os.getenv("DB_NAME",     "dbcopilot_db")
DB_USER     = os.getenv("DB_USER",     "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
DB_PORT     = int(os.getenv("DB_PORT", "5432"))

EXCLUDED_TABLES = {"users", "query_history"}

TYPE_MAP = {
    "character varying": "varchar",
    "integer":           "integer",
    "bigint":            "integer",
    "smallint":          "integer",
    "numeric":           "numeric",
    "decimal":           "numeric",
    "real":              "numeric",
    "double precision":  "numeric",
    "timestamp without time zone": "timestamp",
    "timestamp with time zone":    "timestamp",
    "boolean": "boolean",
    "date":    "date",
    "text":    "text",
}


# ── Live schema from PostgreSQL ────────────────────────────────────────────────

def fetch_live_schema() -> str:
    conn = psycopg2.connect(
        host=DB_HOST, dbname=DB_NAME, user=DB_USER,
        password=DB_PASSWORD, port=DB_PORT
    )
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("""
                SELECT table_name, column_name, data_type, column_default
                FROM information_schema.columns
                WHERE table_schema = 'public'
                ORDER BY table_name, ordinal_position
            """)
            all_columns = cur.fetchall()

            cur.execute("""
                SELECT kcu.table_name, kcu.column_name
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu
                  ON tc.constraint_name = kcu.constraint_name
                 AND tc.table_schema    = kcu.table_schema
                WHERE tc.constraint_type = 'PRIMARY KEY'
                  AND tc.table_schema    = 'public'
            """)
            pks = {(r["table_name"], r["column_name"]) for r in cur.fetchall()}

            cur.execute("""
                SELECT kcu.table_name, kcu.column_name,
                       ccu.table_name AS ref_table, ccu.column_name AS ref_col
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu
                  ON tc.constraint_name = kcu.constraint_name
                 AND tc.table_schema    = kcu.table_schema
                JOIN information_schema.constraint_column_usage ccu
                  ON ccu.constraint_name = tc.constraint_name
                WHERE tc.constraint_type = 'FOREIGN KEY'
                  AND tc.table_schema    = 'public'
            """)
            fks = {
                (r["table_name"], r["column_name"]): f"{r['ref_table']}.{r['ref_col']}"
                for r in cur.fetchall()
            }
    finally:
        conn.close()

    table_cols: dict = defaultdict(list)
    for col in all_columns:
        t = col["table_name"]
        if t not in EXCLUDED_TABLES:
            table_cols[t].append(col)

    parts = []
    for table, cols in table_cols.items():
        col_defs = []
        for col in cols:
            name  = col["column_name"]
            dtype = TYPE_MAP.get(col["data_type"], col["data_type"])
            tags  = []
            if (table, name) in pks:
                tags.append("PK")
            if (table, name) in fks:
                tags.append(f"FK→{fks[(table, name)]}")
            if col.get("column_default") and "nextval" in str(col["column_default"]):
                tags.append("SERIAL")
            tag_str = f", {', '.join(tags)}" if tags else ""
            col_defs.append(f"{name} ({dtype}{tag_str})")
        parts.append(f"Table: {table}\n  Columns: {', '.join(col_defs)}")

    return "\n\n".join(parts)


# ── SQL helpers ────────────────────────────────────────────────────────────────

def clean_sql(sql: str) -> str:
    fetch_match = re.search(r"FETCH\s+(?:FIRST|NEXT)\s+(\d+)\s+ROWS?\s+ONLY", sql, re.IGNORECASE)
    if fetch_match:
        fetch_n = fetch_match.group(1)
        sql = re.sub(r"\s*FETCH\s+(?:FIRST|NEXT)\s+\d+\s+ROWS?\s+ONLY", "", sql, flags=re.IGNORECASE)
        if re.search(r"\bLIMIT\s+100\b", sql, re.IGNORECASE):
            sql = re.sub(r"\bLIMIT\s+100\b", f"LIMIT {fetch_n}", sql, flags=re.IGNORECASE)
        elif not re.search(r"\bLIMIT\s+\d+", sql, re.IGNORECASE):
            sql = sql.rstrip("; ") + f" LIMIT {fetch_n}"
    return sql.strip().rstrip(";") + ";"


def extract_sql(raw: str) -> str:
    raw = re.sub(r"```sql\s*", "", raw, flags=re.IGNORECASE)
    raw = re.sub(r"```\s*",    "", raw)
    raw = raw.strip()

    match = re.search(r"(SELECT\b.+?)(?:;|$)", raw, re.IGNORECASE | re.DOTALL)
    if match:
        sql = match.group(1).strip()
        sql = sql + ";" if not sql.endswith(";") else sql
        return clean_sql(sql)
    return clean_sql(raw)


def build_prompt(query: str, schema: str) -> str:
    return f"""You are a PostgreSQL SQL expert. Convert natural language to a valid PostgreSQL SELECT query.

STRICT RULES:
1. Output ONLY the raw SQL query — no markdown, no code blocks, no explanation text.
2. Only generate SELECT queries. Never use DELETE, UPDATE, INSERT, DROP, ALTER, or TRUNCATE.
3. Row limiting: use ONLY the LIMIT clause. Never use FETCH FIRST / FETCH NEXT / ROWS ONLY.
   - If the user says "top N", "first N", "N records", etc. → use LIMIT N.
   - If the user does not specify a count → use LIMIT 100.
4. Choose the correct table from the schema that best matches the user's request.
5. Use exact column and table names from the schema below.
6. If the query is ambiguous, make a reasonable assumption.

Database Schema (live from the database):
{schema}

Natural language query: "{query}"

SQL:"""


async def call_ollama(prompt: str) -> str:
    async with httpx.AsyncClient(timeout=120.0) as client:
        response = await client.post(
            f"{OLLAMA_URL}/api/generate",
            json={"model": OLLAMA_MODEL, "prompt": prompt, "stream": False},
        )
        response.raise_for_status()
        return response.json().get("response", "").strip()


# ── Request / Response models ──────────────────────────────────────────────────

class GenerateSqlRequest(BaseModel):
    query: str


class GenerateSqlResponse(BaseModel):
    sql: str
    explanation: str


# ── Endpoints ──────────────────────────────────────────────────────────────────

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

    try:
        schema = fetch_live_schema()
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Cannot fetch schema from database: {str(e)}")

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
        raise HTTPException(status_code=503, detail="Cannot connect to Ollama. Make sure Ollama is running.")
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Ollama took too long to respond. Try a smaller model.")
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
