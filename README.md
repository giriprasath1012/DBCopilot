# DBCopilot — AI-Powered Natural Language Database Query Platform

Ask questions about your database in plain English. DBCopilot converts natural language into SQL using a local LLM (Ollama + Llama3), executes the query, and displays results in a professional chat UI with tables, charts, and CSV export — all running fully on your machine with no cloud dependency.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         User's Browser                              │
└────────────────────────────┬────────────────────────────────────────┘
                             │  http://localhost:3000
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│              Frontend  (React 18 + Vite 5 + Recharts)               │
│                       nginx · port 80 → 3000                        │
│                                                                     │
│  ┌────────────┐  ┌─────────────┐  ┌──────────┐  ┌──────────────┐   │
│  │ LoginPage  │  │RegisterPage │  │ ChatPage │  │   Sidebar    │   │
│  └────────────┘  └─────────────┘  └────┬─────┘  └──────┬───────┘   │
│                                        │               │           │
│  ┌─────────────────────────────────────▼───────────────▼─────────┐ │
│  │           Axios  (JWT interceptor · baseURL /api)              │ │
│  └──────────────────────────────────┬──────────────────────────── ┘ │
└─────────────────────────────────────│─────────────────────────────  ┘
                                      │  /api/*  proxied by nginx
                                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   Backend  (Spring Boot 3.4.1)                      │
│                    Java 17 · port 8080                              │
│                                                                     │
│  ┌───────────────┐  ┌──────────────┐  ┌────────────────────────┐   │
│  │ AuthController│  │ChatController│  │HistoryController       │   │
│  │ /api/auth/**  │  │/api/chat/**  │  │/api/history/**         │   │
│  └──────┬────────┘  └──────┬───────┘  └───────────┬────────────┘   │
│         │                  │                       │                │
│  ┌──────▼────────┐  ┌──────▼──────┐  ┌────────────▼────────────┐   │
│  │  AuthService  │  │ ChatService │  │  QueryHistoryService     │   │
│  └──────┬────────┘  └──┬──────┬───┘  └────────────┬────────────┘   │
│         │              │      │                    │                │
│  ┌──────▼──────────────▼┐  ┌──▼──────────┐  ┌────▼───────────────┐ │
│  │ Spring Security 6    │  │SqlValidator │  │ JPA / Hibernate    │ │
│  │ JWT (JJWT 0.12.6)   │  │(SELECT only)│  │ JdbcTemplate       │ │
│  └──────────────────────┘  └──┬──────────┘  └────────────┬───────┘ │
└─────────────────────────────── │ ──────────────────────── │ ───────┘
                                 │  WebClient (async 120s)  │ JDBC
                                 ▼                          ▼
┌──────────────────────────┐        ┌────────────────────────────────┐
│  AI Service  (FastAPI)   │        │  PostgreSQL 16  · port 5432    │
│  Python 3.12 · port 8000 │        │                                │
│                          │        │  Business tables:              │
│  POST /generate-sql      │        │  · customers  · employees      │
│                          │        │  · products   · orders         │
│  Live schema introspect  │        │  · departments· suppliers      │
│  (SQLAlchemy, multi-DB)  │        │  · supplier_products           │
│  CHECK constraint parser │        │  · invoices   · leave_requests │
│  Prompt engineering +    │        │                                │
│  SQL extraction          │        │  App tables (AI-hidden):       │
└────────────┬─────────────┘        │  · users  · query_history      │
             │ httpx (async)        └────────────────────────────────┘
             ▼
┌──────────────────────────┐
│   Ollama  · port 11434   │
│   Model: llama3 (4.7 GB) │
│   Runs on CPU / GPU      │
└──────────────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 18, React Router v6, Recharts, Axios, Vite 5 |
| Styling | CSS custom properties design token system (dark/light theme) |
| Backend | Spring Boot 3.4.1, Java 17, Spring Security 6, JJWT 0.12.6, WebFlux |
| AI Service | FastAPI, Python 3.12, SQLAlchemy, httpx, Pydantic v2, Uvicorn |
| LLM | Ollama (llama3 · 4.7 GB) — runs fully locally, no API key needed |
| Database | PostgreSQL 16 (MySQL, Oracle, SQL Server, H2 also supported) |
| Infrastructure | Docker, Docker Compose, nginx |

---

## Features

### AI & Query
- **Natural language to SQL** — type a question in plain English, get results instantly
- **Live schema introspection** — AI reads your actual table structure and CHECK constraints on every query, so it always knows valid column values (e.g. `'ACTIVE'` not `'active'`)
- **SQL safety** — server-side validator blocks all non-SELECT statements
- **Read-only enforcement** — only SELECT queries are allowed; INSERT/UPDATE/DELETE are rejected with a clear message

### UI & Experience
- **Professional dark/light theme** — persistent toggle, CSS design token system
- **Paginated result table** — status-aware color badges (green/red/yellow), numeric right-alignment, null indicators
- **Bar chart** — auto-detected numeric columns rendered with Recharts, theme-aware colors
- **SQL viewer** — toggle the generated SQL for any query with a one-click copy button
- **CSV export** — authenticated one-click download of any result set
- **Query history** — last 20 queries in the sidebar, click to reload, × to delete
- **Suggestion cards** — categorised quick-start prompts on empty state

### Multi-Database Support
- **PostgreSQL** (default)
- **MySQL**
- **Oracle**
- **SQL Server**
- **H2**

Switch database by updating `DB_TYPE` and connection variables in `docker-compose.yml`.

### Fully Local & Private
- No cloud LLM, no external API calls
- All data stays on your machine

---

## Database Schema

The included seed database has ~300+ realistic records across 9 business tables:

| Table | Rows | Description |
|-------|------|-------------|
| `customers` | 50 | Name, city, email, phone, status (ACTIVE/INACTIVE) |
| `employees` | 35 | Name, department, designation, salary, joining date |
| `products` | 30 | Name, category, price, stock |
| `orders` | 123 | Customer orders with status (PENDING/COMPLETED/CANCELLED) |
| `departments` | 8 | Name, head, budget, location |
| `suppliers` | 10 | Name, contact, city, country, status |
| `supplier_products` | 25 | Supplier–product mapping with unit price |
| `invoices` | 95 | Invoice amount, due date, status (PAID/UNPAID/OVERDUE) |
| `leave_requests` | 47 | Employee leave with type and status (PENDING/APPROVED/REJECTED) |

---

## Prerequisites

| Tool | Version |
|------|---------|
| Docker Desktop | 4.x+ |
| RAM | 16 GB minimum (llama3 needs ~8 GB) |
| Disk | 15 GB free (llama3 model = 4.7 GB) |

> **Windows users:** Docker Desktop requires WSL 2 and hardware virtualisation (Intel VT-x / AMD-V) enabled in BIOS.

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/giriprasath1012/DBCopilot.git
cd DBCopilot
```

### 2. Build and start all containers

```bash
docker compose up --build -d
```

This starts five containers: `postgres`, `ollama`, `ai-service`, `backend`, `frontend`.

### 3. Pull the Llama3 model *(first run only — ~4.7 GB download)*

```bash
docker exec -it dbcopilot-ollama ollama pull llama3
```

### 4. Open the app

```
http://localhost:3000
```

Register a new account and start querying your database in plain English.

---

## Sample Queries

| Natural Language | Generated SQL (example) |
|-----------------|------------------------|
| Show all active customers from Bangalore | `SELECT * FROM customers WHERE city = 'Bangalore' AND status = 'ACTIVE'` |
| List employees in Engineering department | `SELECT * FROM employees WHERE department = 'Engineering'` |
| Top 5 products by price | `SELECT * FROM products ORDER BY price DESC LIMIT 5` |
| Show all pending orders | `SELECT * FROM orders WHERE status = 'PENDING'` |
| Show all overdue invoices | `SELECT * FROM invoices WHERE status = 'OVERDUE'` |
| List pending leave requests | `SELECT * FROM leave_requests WHERE status = 'PENDING'` |
| Total order amount by customer | `SELECT c.customer_name, SUM(o.amount) FROM customers c JOIN orders o ON c.customer_id = o.customer_id GROUP BY c.customer_name` |
| Department budgets ranked highest first | `SELECT department_name, budget FROM departments ORDER BY budget DESC` |

---

## Project Structure

```
DBCopilot/
├── docker-compose.yml
├── database/
│   └── schema/
│       └── init.sql              # Tables + seed data (9 tables, ~300+ rows)
├── ai-service/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app/
│       └── main.py               # FastAPI: /generate-sql, live schema introspection
├── backend/
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/main/java/com/dbcopilot/backend/
│       ├── config/               # SecurityConfig, WebClientConfig
│       ├── controller/           # AuthController, ChatController,
│       │                         # HistoryController, ExportController
│       ├── dto/                  # Request/Response POJOs
│       ├── entity/               # User, QueryHistory (JPA)
│       ├── repository/           # Spring Data JPA repositories
│       ├── security/             # JwtUtil, JwtAuthFilter, UserDetailsService
│       ├── service/              # AuthService, ChatService, QueryHistoryService
│       └── validator/            # SqlValidator (blocks non-SELECT)
└── frontend/
    ├── Dockerfile
    ├── nginx.conf
    ├── package.json
    └── src/
        ├── api/                  # axios.js, authApi.js, chatApi.js
        ├── context/              # AuthContext (JWT), ThemeContext (dark/light)
        ├── pages/                # LoginPage, RegisterPage, ChatPage
        └── components/           # Sidebar, ChatMessage, ResultTable, ResultChart
```

---

## API Endpoints

### Auth
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/register` | Register a new user |
| POST | `/api/auth/login` | Login, returns JWT token |

### Chat
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/chat/query` | Submit a natural language query |

### History
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/history` | Get last 20 queries for current user |
| DELETE | `/api/history/{id}` | Delete a specific history entry |

### Export
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/export/csv/{queryId}` | Download results as CSV |

> All endpoints except `/api/auth/**` require `Authorization: Bearer <token>` header.

---

## Configuration

### Switching Databases

Edit `docker-compose.yml` and update the `ai-service` environment:

```yaml
# PostgreSQL (default)
- DB_TYPE=postgresql
- DB_HOST=postgres
- DB_PORT=5432
- DB_NAME=dbcopilot_db
- DB_USER=postgres
- DB_PASSWORD=postgres

# Or use a full URL (overrides all individual variables above):
# - DB_URL=mysql+pymysql://user:pass@host:3306/dbname
```

Update the `backend` datasource URL to match:

```yaml
# MySQL
- SPRING_DATASOURCE_URL=jdbc:mysql://host:3306/dbname?useSSL=false&allowPublicKeyRetrieval=true
# Oracle
- SPRING_DATASOURCE_URL=jdbc:oracle:thin:@host:1521/service_name
# SQL Server
- SPRING_DATASOURCE_URL=jdbc:sqlserver://host:1433;databaseName=dbname;encrypt=true;trustServerCertificate=true
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_TYPE` | `postgresql` | Database dialect for AI service |
| `DB_EXCLUDE_TABLES` | `users,query_history` | Tables hidden from the AI |
| `POSTGRES_PASSWORD` | `postgres` | PostgreSQL password |
| `APP_JWT_SECRET` | *(64-char string)* | JWT signing key — **change in production** |
| `APP_JWT_EXPIRATION` | `86400000` | Token TTL in ms (24 hours) |
| `OLLAMA_MODEL` | `llama3` | Ollama model name |
| `AI_SERVICE_URL` | `http://ai-service:8000` | AI service internal URL |

---

## Local Network Access

To share with colleagues on the same network:

```bash
# Windows
ipconfig | findstr "IPv4"

# Linux / macOS
hostname -I
```

Then share `http://<your-ip>:3000`. Ensure port 3000 is open in your firewall.

---

## License

MIT
