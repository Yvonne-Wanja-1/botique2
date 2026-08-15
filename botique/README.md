# botique

Flutter boutique app for "Queens' Touch" with a Node.js + Express + TypeScript backend.

## Requirements

- Flutter >= 3.44 (Dart ^3.12)
- Node.js >= 18
- PostgreSQL >= 14 (only needed for the live API mode)

## Running the Flutter app

The app ships with in-memory mock repositories by default — no backend needed to boot.

```powershell
flutter run                          # mock repositories (default)
flutter run -d windows --dart-define=USE_API=true    # live backend on http://localhost:8080
```

To point at a different backend:

```powershell
flutter run -d windows --dart-define=USE_API=true --dart-define=API_BASE_URL=http://localhost:8080
```

When `USE_API` is enabled the app talks to the real API and sends `X-User-Id` / `X-User-Role` headers (dev auth stub) until real authentication is implemented. Demo-account sign-in maps to the seeded backend user ids so the stub resolves against the seeded database.

## Backend & API

### 1. Create the database

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -c "CREATE DATABASE queens_touch;"
```

### 2. Apply the schema (idempotent)

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d queens_touch -f database\schema.sql
```

### 3. Configure the backend

```powershell
Copy-Item backend\.env.example backend\.env
# edit backend\.env -> set DATABASE_URL (or DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD)
```

### 4. Run

```powershell
cd backend
npm install
npm run dev
```

### 5. Sanity check

```powershell
Invoke-RestMethod http://localhost:8080/health
Invoke-RestMethod http://localhost:8080/api/products -Headers @{ 'x-user-id' = '00000000-0000-0000-0000-000000000201'; 'x-user-role' = 'customer' }
```

See `backend/README.md` for env variables, scripts, the API envelope, and the test strategy.

## Tests

```powershell
cd backend; npm test; npm run typecheck   # backend suites (pg-mem, no DB needed)
flutter test                              # Flutter widget + repository tests
```