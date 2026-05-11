# DBCopilot — AI-Powered Natural Language Database Query Platform

Ask questions about your database in plain English. DBCopilot converts natural language into SQL using a local LLM (Ollama + Llama3), executes the query against PostgreSQL, and displays results in a conversational chat UI with tables, charts, and CSV export.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         User's Browser                              │
└────────────────────────────┬────────────────────────────────────────┘
                             │  http://localhost:3000
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Frontend  (React 18 + Vite)                      │
│                     nginx · port 80 → 3000                          │
│                                                                     │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────┐  ┌───────────┐  │
│  │  LoginPage  │  │  RegisterPage│  │  ChatPage │  │  Sidebar  │  │
│  └─────────────┘  └──────────────┘  └─────┬─────┘  └─────┬─────┘  │
│                                           │               │        │
│  ┌────────────────────────────────────────▼───────────────▼──────┐ │
│  │          Axios  (JWT interceptor · baseURL /api)               │ │
│  └──────────────────────────────────┬─────────────────────────── ┘ │
└─────────────────────────────────────│───────────────────────────────┘
                                      │  /api/*  proxied by nginx
                                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   Backend  (Spring Boot 3.4.1)                      │
│                    Java 17 · port 8080                              │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────────┐ │
│  │ AuthController│  │ChatController│  │HistoryController          │ │
│  │ /api/auth/**  │  │/api/chat/**  │  │/api/history/**            │ │
│  └──────┬───────┘  └──────┬───────┘  └─────────────┬─────────────┘ │
│         │                 │                         │               │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌─────────────▼─────────────┐ │
│  │  AuthService │  │  ChatService │  │    QueryHistoryService     │ │
│  └──────┬───────┘  └──┬───────┬───┘  └─────────────┬─────────────┘ │
│         │             │       │                     │               │
│  ┌──────▼─────────────▼┐  ┌───▼──────┐  ┌──────────▼─────────────┐ │
│  │  Spring Security 6  │  │SqlValid- │  │   JPA / Hibernate      │ │
│  │  JWT (JJWT 0.12.6)  │  │ator      │  │   JdbcTemplate         │ │
│  └─────────────────────┘  └───┬──────┘  └──────────┬─────────────┘ │
└──────────────────────────────-│──────────────────── │───────────────┘
                                │ WebClient           │
                                │ (async, 120s TO)    │ JDBC
                                ▼                     ▼
┌───────────────────────────┐      ┌──────────────────────────────────┐
│   AI Service  (FastAPI)   │      │   PostgreSQL 16                  │
│   Python 3.12 · port 8000 │      │   port 5432                     │
│                           │      │                                  │
│  POST /generate-sql       │      │  tables:                         │
│  POST /explain-sql        │      │  · users                         │
│                           │      │  · query_history                 │
│  prompt engineering +     │      │  · customers                     │
│  SQL extraction           │      │  · employees                     │
└────────────┬──────────────┘      │  · products                     │
             │ httpx (async)       │  · orders                        │
             ▼                     └──────────────────────────────────┘
┌───────────────────────────┐
│   Ollama  · port 11434    │
│                           │
│   Model: llama3 (4.7 GB)  │
│   Runs on CPU / GPU       │
└───────────────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 18, React Router v6, Recharts, Axios, Vite 5 |
| Backend | Spring Boot 3.4.1, Java 17, Spring Security 6, JJWT 0.12.6, WebFlux |
| AI Service | FastAPI, Python 3.12, httpx, Pydantic v2, Uvicorn |
| LLM | Ollama (llama3 · 4.7 GB) — runs fully locally, no API key needed |
| Database | PostgreSQL 16 |
| Infrastructure | Docker, Docker Compose, nginx |

---

## Features

- **Natural language to SQL** — type a question, get results instantly
- **JWT authentication** — register / login, all routes protected
- **Result table** — paginated, sticky headers, up to 500 rows
- **Bar chart** — auto-detected numeric columns rendered with Recharts
- **SQL viewer** — toggle the generated SQL for any query
- **CSV export** — one-click download of any result set
- **Query history** — last 20 queries in the sidebar, click to reload, × to delete
- **SQL safety** — server-side validator blocks all non-SELECT statements
- **Fully local** — no cloud LLM, no data leaves your machine

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
docker-compose up --build -d
```

This starts five containers: `postgres`, `ollama`, `ai-service`, `backend`, `frontend`.

### 3. Pull the Llama3 model (first run only — ~4.7 GB download)

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
| Show all customers from Bangalore | `SELECT * FROM customers WHERE city = 'Bangalore'` |
| How many employees joined this year? | `SELECT COUNT(*) FROM employees WHERE EXTRACT(YEAR FROM hire_date) = EXTRACT(YEAR FROM NOW())` |
| Top 5 products by price | `SELECT * FROM products ORDER BY price DESC LIMIT 5` |
| Total order amount by customer | `SELECT c.name, SUM(o.amount) FROM customers c JOIN orders o ON c.id = o.customer_id GROUP BY c.name` |

---

## Project Structure

```
DBCopilot/
├── docker-compose.yml
├── database/
│   └── schema/
│       └── init.sql              # Tables + seed data
├── ai-service/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app/
│       └── main.py               # FastAPI: /generate-sql, /explain-sql
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
        ├── context/              # AuthContext (JWT storage)
        ├── routes/               # PrivateRoute
        ├── pages/                # LoginPage, RegisterPage, ChatPage
        └── components/           # Sidebar, ChatMessage, ResultTable,
                                  # ResultChart
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

## Environment Variables

These can be overridden in `docker-compose.yml` for production:

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_PASSWORD` | `postgres` | PostgreSQL password |
| `APP_JWT_SECRET` | *(64-char string)* | JWT signing key — **change in production** |
| `APP_JWT_EXPIRATION` | `86400000` | Token TTL in ms (24 hours) |
| `OLLAMA_MODEL` | `llama3` | Ollama model to use |
| `AI_SERVICE_URL` | `http://ai-service:8000` | AI service URL |

---

## Local Network Access

To share with colleagues on the same network, find your machine's IP:

```bash
# Windows
ipconfig | findstr "IPv4"

# Linux / macOS
hostname -I
```

Then share `http://<your-ip>:3000`. Ensure port 3000 is allowed in your firewall.

---

## License

MIT
