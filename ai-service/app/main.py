import os
import re
from collections import defaultdict

import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy import create_engine, inspect as sa_inspect, text

app = FastAPI(title="DBCopilot AI Service", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Ollama config ──────────────────────────────────────────────────────────────
OLLAMA_URL   = os.getenv("OLLAMA_URL",   "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3")

# ── Database config ────────────────────────────────────────────────────────────
# DB_TYPE: postgresql | mysql | oracle | sqlserver | h2
DB_TYPE     = os.getenv("DB_TYPE",     "postgresql")
DB_HOST     = os.getenv("DB_HOST",     "localhost")
DB_NAME     = os.getenv("DB_NAME",     "dbcopilot_db")
DB_USER     = os.getenv("DB_USER",     "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
DB_PORT     = os.getenv("DB_PORT",     "")           # auto-default per type if blank
DB_URL      = os.getenv("DB_URL",      "")           # full URL overrides all above

# Tables managed by the app itself — excluded from the AI schema
EXCLUDED_TABLES = set(os.getenv("DB_EXCLUDE_TABLES", "users,query_history").split(","))

# ── Per-database defaults ──────────────────────────────────────────────────────
DB_DEFAULTS = {
    "postgresql": {"port": "5432", "dialect": "PostgreSQL",  "limit_syntax": "LIMIT {n}"},
    "mysql":      {"port": "3306", "dialect": "MySQL",       "limit_syntax": "LIMIT {n}"},
    "oracle":     {"port": "1521", "dialect": "Oracle SQL",  "limit_syntax": "FETCH FIRST {n} ROWS ONLY"},
    "sqlserver":  {"port": "1433", "dialect": "SQL Server",  "limit_syntax": "TOP {n}"},
    "h2":         {"port": "9092", "dialect": "H2",          "limit_syntax": "LIMIT {n}"},
}

TYPE_MAP = {
    "character varying": "varchar", "varchar":  "varchar", "nvarchar": "varchar",
    "char": "varchar",  "text": "text",  "clob": "text",
    "integer": "integer", "int": "integer", "bigint": "integer",
    "smallint": "integer", "number": "numeric",
    "numeric": "numeric", "decimal": "numeric",
    "real": "numeric", "float": "numeric", "double precision": "numeric",
    "timestamp without time zone": "timestamp", "timestamp with time zone": "timestamp",
    "timestamp": "timestamp", "datetime": "timestamp",
    "date": "date", "boolean": "boolean", "bool": "boolean",
}


def get_db_url() -> str:
    if DB_URL:
        return DB_URL
    port = DB_PORT or DB_DEFAULTS.get(DB_TYPE, {}).get("port", "5432")
    if DB_TYPE == "postgresql":
        return f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{port}/{DB_NAME}"
    if DB_TYPE == "mysql":
        return f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{port}/{DB_NAME}"
    if DB_TYPE == "oracle":
        return f"oracle+cx_oracle://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{port}/{DB_NAME}"
    if DB_TYPE == "sqlserver":
        return (f"mssql+pyodbc://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{port}/{DB_NAME}"
                f"?driver=ODBC+Driver+17+for+SQL+Server&TrustServerCertificate=yes")
    if DB_TYPE == "h2":
        return f"h2+jdbc:h2:tcp://{DB_HOST}:{port}/{DB_NAME}"
    return f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{port}/{DB_NAME}"


def normalize_type(raw: str) -> str:
    lower = raw.lower().split("(")[0].strip()
    return TYPE_MAP.get(lower, lower)


# ── Live schema via SQLAlchemy (works for any supported database) ───────────────
def fetch_live_schema() -> str:
    engine = create_engine(get_db_url())
    inspector = sa_inspect(engine)

    parts = []
    for table_name in sorted(inspector.get_table_names()):
        if table_name.lower() in {t.lower() for t in EXCLUDED_TABLES}:
            continue

        columns   = inspector.get_columns(table_name)
        pk_info   = inspector.get_pk_constraint(table_name)
        pk_cols   = set(pk_info.get("constrained_columns", []))
        fk_info   = inspector.get_foreign_keys(table_name)
        fk_map    = {}
        for fk in fk_info:
            for col, ref_col in zip(fk["constrained_columns"], fk["referred_columns"]):
                fk_map[col] = f"{fk['referred_table']}.{ref_col}"

        # Check constraints → expose allowed enum values to LLM
        check_values: dict = {}
        try:
            for ck in inspector.get_check_constraints(table_name):
                sqltext = ck.get("sqltext", "")
                # Handles: col::type = ANY(...) [PostgreSQL] and col IN (...)
                col_match = re.search(
                    r"(\w+)(?:::\w+(?:\s+\w+)*)?\s*=\s*ANY|(\w+)\s+IN\b",
                    sqltext, re.IGNORECASE
                )
                # Exclude type-cast names: skip values directly preceded by ::
                vals = re.findall(r"(?<![:\w])'([^']+)'", sqltext)
                if col_match and vals:
                    col_name = col_match.group(1) or col_match.group(2)
                    check_values[col_name] = vals
        except Exception:
            pass

        col_defs = []
        for col in columns:
            name  = col["name"]
            dtype = normalize_type(str(col["type"]))
            tags  = []
            if name in pk_cols:
                tags.append("PK")
            if name in fk_map:
                tags.append(f"FK→{fk_map[name]}")
            if col.get("autoincrement"):
                tags.append("SERIAL")
            if name in check_values:
                allowed = ", ".join(f"'{v}'" for v in check_values[name])
                tags.append(f"values: {allowed}")
            tag_str = f", {', '.join(tags)}" if tags else ""
            col_defs.append(f"{name} ({dtype}{tag_str})")

        parts.append(f"Table: {table_name}\n  Columns: {', '.join(col_defs)}")

    engine.dispose()
    return "\n\n".join(parts)


# ── SQL helpers ────────────────────────────────────────────────────────────────
def clean_sql(sql: str) -> str:
    fetch_match = re.search(r"FETCH\s+(?:FIRST|NEXT)\s+(\d+)\s+ROWS?\s+ONLY", sql, re.IGNORECASE)
    if fetch_match and DB_TYPE not in ("oracle", "sqlserver"):
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
        return clean_sql(sql + (";" if not sql.endswith(";") else ""))
    return clean_sql(raw)


def build_prompt(query: str, schema: str) -> str:
    meta   = DB_DEFAULTS.get(DB_TYPE, DB_DEFAULTS["postgresql"])
    dialect = meta["dialect"]
    limit   = meta["limit_syntax"].replace("{n}", "N")

    return f"""You are a {dialect} SQL expert. Convert natural language to a valid {dialect} SELECT query.

STRICT RULES:
1. Output ONLY the raw SQL query — no markdown, no code blocks, no explanation text.
2. Only generate SELECT queries. Never use DELETE, UPDATE, INSERT, DROP, ALTER, or TRUNCATE.
3. Row limiting: use the correct syntax for {dialect}: {limit}
   - If the user says "top N", "first N", or "N records" → use that number.
   - If no count is specified → use 100 as the default limit.
4. Choose the correct table that best matches the user's request.
5. Use exact column and table names from the schema below.
6. String values are case-sensitive. Always use the exact case shown in the schema's "values:" annotations.
7. If the query is ambiguous, make a reasonable assumption.

Database Schema (live from the connected {dialect} database):
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


# ── Models ─────────────────────────────────────────────────────────────────────
class GenerateSqlRequest(BaseModel):
    query: str


class GenerateSqlResponse(BaseModel):
    sql: str
    explanation: str


# ── Endpoints ──────────────────────────────────────────────────────────────────
@app.get("/")
def root():
    return {"message": "DBCopilot AI Service", "status": "ok",
            "model": OLLAMA_MODEL, "db_type": DB_TYPE}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/schema")
def get_schema():
    """Expose the live schema — useful for debugging."""
    try:
        return {"schema": fetch_live_schema(), "db_type": DB_TYPE}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Schema fetch failed: {str(e)}")


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

        return GenerateSqlResponse(sql=sql, explanation=f"Converted '{request.query}' into a SQL query.")

    except httpx.ConnectError:
        raise HTTPException(status_code=503, detail="Cannot connect to Ollama. Make sure Ollama is running.")
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Ollama took too long to respond.")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI generation error: {str(e)}")


@app.post("/explain-sql")
async def explain_sql(body: dict):
    sql = body.get("sql", "")
    if not sql:
        raise HTTPException(status_code=400, detail="sql field is required")
    prompt = f"Explain this SQL query in plain English in 1-2 sentences:\n\nSQL: {sql}\n\nExplanation:"
    try:
        return {"explanation": (await call_ollama(prompt)).strip()}
    except Exception:
        return {"explanation": "Query executed successfully."}
