# 🗄️ Database as Code — Automated Schema Migration & DevOps Pipeline

> Treating database schema exactly like application code — versioned, tested, automated,
> and deployed through a full DevOps pipeline using Flyway, Docker, GitHub Actions,
> Kubernetes, and Terraform.

---

## 📌 Table of Contents

- [Problem Statement](#-problem-statement)
- [Solution](#-solution)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Phase 1 — Local Database Setup](#-phase-1--local-database-setup)
- [Phase 2 — Migration Files](#-phase-2--migration-files)
- [Phase 3 — Version Control](#-phase-3--version-control)
- [Phase 4 — CI/CD Pipeline](#-phase-4--cicd-pipeline)
- [Phase 5 — Kubernetes Deployment](#-phase-5--kubernetes-deployment)
- [Phase 6 — Terraform Infrastructure](#-phase-6--terraform-infrastructure)
- [Phase 7 — Schema Validation](#-phase-7--schema-validation)
- [How to Add a New Migration](#-how-to-add-a-new-migration)
- [Rollback Strategy](#-rollback-strategy)
- [Environment Flow](#-environment-flow)
- [Setup Checklist](#-setup-checklist)
- [Key Learnings](#-key-learnings)

---

## ❌ Problem Statement

Traditional database management is broken in real-world teams:

| Problem | Impact |
|---------|--------|
| Manual SQL execution directly on databases | Human error, no audit trail |
| No version tracking for schema changes | Cannot reproduce or roll back safely |
| Inconsistent dev vs staging vs production | "Works on my machine" failures |
| No automated testing for schema changes | Silent failures reach production |
| Infrastructure created by clicking a UI | Not reproducible, not reviewable |

---

## ✅ Solution

Treat the database schema exactly like application code:

- Every change is a **versioned SQL file** committed to Git
- A **CI/CD pipeline** automatically applies and validates every change
- **Kubernetes** manages the database and runs migrations as controlled Jobs
- **Terraform** provisions the entire infrastructure from a single command
- **Zero manual steps** — from writing a migration to a validated deployment

---

## 🛠️ Tech Stack

| Tool | Version | Purpose |
|------|---------|---------|
| PostgreSQL | 16 | Relational database |
| Flyway | 10 | Migration engine — applies versioned SQL files in order |
| Docker | Latest | Containerisation — consistent environments everywhere |
| Git + GitHub | — | Version control — every schema change is tracked |
| GitHub Actions | — | CI/CD — automates migrations and tests on every push |
| Kubernetes (Minikube) | Latest | Orchestration — manages DB pods and migration Jobs |
| Terraform | Latest | Infrastructure as Code — provisions everything from .tf files |

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  DEVELOPER                                                   │
│  Writes V5__add_foreign_keys.sql  →  git push               │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  GITHUB REPOSITORY                                           │
│  migrations/  k8s/  terraform/  tests/  .github/workflows/  │
└──────────────────────┬───────────────────────────────────────┘
                       │  triggers automatically on push
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  GITHUB ACTIONS CI/CD PIPELINE                               │
│                                                              │
│  Step 1 → Spin up ephemeral PostgreSQL container             │
│  Step 2 → Run Flyway migrations on test database             │
│  Step 3 → Run verify_schema.sql integration tests            │
│  Step 4 → PASS: promote  |  FAIL: block merge immediately    │
└──────────────────────┬───────────────────────────────────────┘
                       │  on success only
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  TERRAFORM                                                   │
│  Provisions infrastructure — container, network, storage     │
│  Everything defined in main.tf — reproducible always         │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  KUBERNETES CLUSTER (Minikube)                               │
│                                                              │
│  ┌──────────────────┐    ┌─────────────────────────────┐    │
│  │  PostgreSQL Pod  │◄───│  Flyway Job                 │    │
│  │  (Deployment)    │    │  runs once → exits cleanly  │    │
│  │  + PVC storage   │    │  + initContainer waits      │    │
│  └──────────────────┘    └─────────────────────────────┘    │
│            ▲                                                 │
│  ┌─────────┴────────┐                                       │
│  │  K8s Service     │  internal networking between pods     │
│  └──────────────────┘                                       │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  RESULT                                                      │
│  Database fully managed as code. Zero manual steps.          │
│  Every change versioned, tested, auditable, reproducible.    │
└──────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
db-as-code/
│
├── migrations/                          # Flyway versioned SQL files
│   ├── V1__create_users.sql             # Create users table
│   ├── V2__create_products.sql          # Create products table
│   ├── V3__create_orders.sql            # Create orders table
│   ├── V4__add_phone_to_users.sql       # Add phone column
│   ├── V5__add_foreign_keys.sql         # Referential integrity
│   ├── V6__add_indexes.sql              # Performance indexes
│   ├── V7__add_status_to_orders.sql     # Evolve orders schema
│   ├── V8__add_temp_column.sql          # Demonstrates a bad migration
│   └── V9__remove_temp_column.sql       # Demonstrates rollback pattern
│
├── k8s/                                 # Kubernetes manifests
│   ├── postgres.yml                     # Secret + PVC + Deployment + Service
│   └── flyway-job.yml                   # ConfigMap + Job + initContainer
│
├── terraform/                           # Infrastructure as Code
│   ├── main.tf                          # Docker provider + PostgreSQL container
│   ├── variables.tf                     # Input variables
│   └── outputs.tf                       # Output values
│
├── tests/
│   └── verify_schema.sql                # Integration tests
│
├── .github/
│   └── workflows/
│       └── ci.yml                       # GitHub Actions pipeline
│
├── docker-compose.yml                   # Local development only
└── README.md                            # This file
```

---

## 🟢 Phase 1 — Local Database Setup

**Purpose:** Run PostgreSQL on your laptop using Docker so you have a real database to develop against without installing PostgreSQL directly.

### docker-compose.yml

```yaml
services:
  db:
    image: postgres:16
    container_name: myapp_db
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: secret
    ports:
      - "5432:5432"
```

### Commands

```cmd
docker compose up -d
docker ps
docker exec -it myapp_db psql -U dev -d myapp
```

---

## 🟢 Phase 2 — Migration Files

**Purpose:** Every database change is written as a versioned SQL file. Flyway reads these in order, tracks which ones ran, and only applies new ones. Schema evolves safely and reproducibly.

**Naming rule:** `V{number}__{description}.sql` — double underscore required.
**Golden rule:** Never edit or delete a migration file after it has been applied.

---

### V1__create_users.sql
```sql
CREATE TABLE users (
    id         SERIAL PRIMARY KEY,
    name       TEXT NOT NULL,
    email      TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### V2__create_products.sql
```sql
CREATE TABLE products (
    id    SERIAL PRIMARY KEY,
    name  TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL
);
```

### V3__create_orders.sql
```sql
CREATE TABLE orders (
    id         SERIAL PRIMARY KEY,
    user_id    INT,
    product_id INT,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### V4__add_phone_to_users.sql
```sql
-- Demonstrates adding a column to an existing table
ALTER TABLE users ADD COLUMN phone TEXT;
```

### V5__add_foreign_keys.sql
```sql
-- Adds referential integrity constraints
ALTER TABLE orders
    ADD CONSTRAINT fk_orders_users
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE orders
    ADD CONSTRAINT fk_orders_products
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;
```

### V6__add_indexes.sql
```sql
-- Improves query performance on common lookups
CREATE INDEX idx_users_email       ON users(email);
CREATE INDEX idx_orders_user_id    ON orders(user_id);
CREATE INDEX idx_orders_product_id ON orders(product_id);
CREATE INDEX idx_orders_created_at ON orders(created_at);
```

### V7__add_status_to_orders.sql
```sql
-- Evolves the orders table to track order lifecycle
ALTER TABLE orders ADD COLUMN status     TEXT        NOT NULL DEFAULT 'pending';
ALTER TABLE orders ADD COLUMN updated_at TIMESTAMPTZ          DEFAULT now();
```

### V8__add_temp_column.sql
```sql
-- Intentionally adds a column to demonstrate rollback
ALTER TABLE users ADD COLUMN temp_data TEXT;
```

### V9__remove_temp_column.sql
```sql
-- Rolls back V8 using a new forward migration (correct Flyway pattern)
ALTER TABLE users DROP COLUMN IF EXISTS temp_data;
```

---

### Run migrations locally (Windows)

```cmd
docker run --rm --add-host=host.docker.internal:host-gateway ^
  -v %cd%\migrations:/flyway/sql flyway/flyway:10 ^
  -url=jdbc:postgresql://host.docker.internal:5432/myapp ^
  -user=dev -password=secret migrate
```

### Verify tables

```cmd
docker exec -it myapp_db psql -U dev -d myapp -c "\dt"
```

Expected:
```
 public | flyway_schema_history | table | dev
 public | orders                | table | dev
 public | products              | table | dev
 public | users                 | table | dev
```

---

## 🟢 Phase 3 — Version Control

**Purpose:** All files live in Git. Every change is tracked, reviewable, and reversible. This is the "as Code" part of Database as Code.

```cmd
git init
git add .
git commit -m "Initial project setup with all migrations"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/db-as-code.git
git push -u origin main
```

---

## 🟢 Phase 4 — CI/CD Pipeline

**Purpose:** Every push to GitHub automatically tests your migrations on a clean database. Bad migrations are caught immediately — never in production.

### .github/workflows/ci.yml

```yaml
name: Schema Migration CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  migrate:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: ci
          POSTGRES_PASSWORD: ci
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 5s
          --health-timeout 5s
          --health-retries 5

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Flyway migrations
        run: |
          docker run --rm \
            --network host \
            -v ${{ github.workspace }}/migrations:/flyway/sql \
            flyway/flyway:10 \
            -url=jdbc:postgresql://localhost:5432/testdb \
            -user=ci -password=ci \
            migrate

      - name: Run integration tests
        run: |
          PGPASSWORD=ci psql \
            -h localhost -U ci -d testdb \
            -f tests/verify_schema.sql
```

### Pipeline flow
```
git push → GitHub Actions triggers → PostgreSQL starts (ephemeral)
→ Flyway applies all migrations → verify_schema.sql runs
→ PASS ✅ safe to merge  |  FAIL ❌ merge blocked
```

---

## 🟢 Phase 5 — Kubernetes Deployment

**Purpose:** Manages the database with production-grade reliability — auto-restart, persistent storage, and controlled migration execution via a Kubernetes Job.

### Install (Windows — run as Administrator)
```cmd
winget install Kubernetes.minikube
winget install Kubernetes.kubectl
minikube start --driver=docker
kubectl get nodes
```

### k8s/postgres.yml
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
stringData:
  POSTGRES_DB: myapp
  POSTGRES_USER: dev
  POSTGRES_PASSWORD: secret
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:16
          envFrom:
            - secretRef:
                name: postgres-secret
          ports:
            - containerPort: 5432
          volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: postgres-storage
      volumes:
        - name: postgres-storage
          persistentVolumeClaim:
            claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
      targetPort: 5432
```

### k8s/flyway-job.yml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: flyway-migrations
data:
  V1__create_users.sql: |
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY, name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE, created_at TIMESTAMPTZ DEFAULT now()
    );
  V2__create_products.sql: |
    CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY, name TEXT NOT NULL, price NUMERIC(10,2) NOT NULL
    );
  V3__create_orders.sql: |
    CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY, user_id INT, product_id INT,
        created_at TIMESTAMPTZ DEFAULT now()
    );
  V4__add_phone_to_users.sql: |
    ALTER TABLE users ADD COLUMN IF NOT EXISTS phone TEXT;
  V5__add_foreign_keys.sql: |
    ALTER TABLE orders ADD CONSTRAINT fk_orders_users
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    ALTER TABLE orders ADD CONSTRAINT fk_orders_products
      FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;
  V6__add_indexes.sql: |
    CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
    CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
  V7__add_status_to_orders.sql: |
    ALTER TABLE orders ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'pending';
    ALTER TABLE orders ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();
---
apiVersion: batch/v1
kind: Job
metadata:
  name: flyway-migrate
spec:
  template:
    spec:
      restartPolicy: Never
      initContainers:
        - name: wait-for-postgres
          image: busybox
          command:
            - sh
            - -c
            - until nc -z postgres-service 5432; do echo waiting; sleep 2; done
      containers:
        - name: flyway
          image: flyway/flyway:10
          args:
            - -url=jdbc:postgresql://postgres-service:5432/myapp
            - -user=dev
            - -password=secret
            - -locations=filesystem:/flyway/sql
            - migrate
          volumeMounts:
            - name: migrations
              mountPath: /flyway/sql
      volumes:
        - name: migrations
          configMap:
            name: flyway-migrations
```

### Deploy commands
```cmd
kubectl apply -f k8s\postgres.yml
kubectl get pods --watch
kubectl apply -f k8s\flyway-job.yml
kubectl get jobs
kubectl logs job/flyway-migrate -c flyway
kubectl exec deployment/postgres -- psql -U dev -d myapp -c "\dt"
```

### Kubernetes resources explained

| Resource | Purpose |
|----------|---------|
| Secret | Stores credentials securely — never plain text |
| PersistentVolumeClaim | Data survives pod restarts and crashes |
| Deployment | Runs PostgreSQL, auto-restarts if it crashes |
| Service | Internal network address so pods can reach DB |
| ConfigMap | Stores migration SQL files inside the cluster |
| Job | Runs Flyway exactly once, exits cleanly |
| initContainer | Waits for PostgreSQL ready before Flyway starts |

---

## 🟢 Phase 6 — Terraform Infrastructure

**Purpose:** Provisions the database environment entirely from code. No manual steps, no UI clicking. Anyone can recreate the exact same environment with one command.

### Install (Windows — run as Administrator)
```cmd
winget install Hashicorp.Terraform
terraform --version
```

### terraform/variables.tf
```hcl
variable "db_name"     { default = "myapp" }
variable "db_user"     { default = "dev" }
variable "db_password" { default = "secret"; sensitive = true }
variable "db_port"     { default = 5433 }
```

### terraform/main.tf
```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "postgres" {
  name = "postgres:16"
}

resource "docker_volume" "postgres_data" {
  name = "terraform_postgres_data"
}

resource "docker_container" "postgres" {
  name  = "terraform_myapp_db"
  image = docker_image.postgres.image_id
  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}"
  ]
  ports {
    internal = 5432
    external = var.db_port
  }
  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }
}
```

### terraform/outputs.tf
```hcl
output "db_container_name" {
  value = docker_container.postgres.name
}
output "db_connection_string" {
  value     = "postgresql://${var.db_user}:${var.db_password}@localhost:${var.db_port}/${var.db_name}"
  sensitive = true
}
```

### Terraform commands
```cmd
cd terraform
terraform init
terraform plan
terraform apply
cd ..
```

### Run Flyway against Terraform database (port 5433)
```cmd
docker run --rm --add-host=host.docker.internal:host-gateway ^
  -v %cd%\migrations:/flyway/sql flyway/flyway:10 ^
  -url=jdbc:postgresql://host.docker.internal:5433/myapp ^
  -user=dev -password=secret migrate
```

---

## 🟢 Phase 7 — Schema Validation

**Purpose:** Fail-fast integration tests. If any table or column is missing after migrations, the pipeline fails immediately before anything reaches production.

### tests/verify_schema.sql
```sql
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'users')
  THEN RAISE EXCEPTION 'FAILED: users table missing'; END IF;

  IF NOT EXISTS (SELECT FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'products')
  THEN RAISE EXCEPTION 'FAILED: products table missing'; END IF;

  IF NOT EXISTS (SELECT FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'orders')
  THEN RAISE EXCEPTION 'FAILED: orders table missing'; END IF;

  IF NOT EXISTS (SELECT FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'phone')
  THEN RAISE EXCEPTION 'FAILED: phone column missing from users'; END IF;

  IF NOT EXISTS (SELECT FROM information_schema.columns
    WHERE table_name = 'orders' AND column_name = 'status')
  THEN RAISE EXCEPTION 'FAILED: status column missing from orders'; END IF;

  RAISE NOTICE 'SUCCESS: All tables and columns verified OK';
END $$;
```

---

## ➕ How to Add a New Migration

```
Step 1 → Create migrations/V10__your_change.sql
Step 2 → Write your SQL inside it
Step 3 → Test locally with Flyway
Step 4 → Update verify_schema.sql if you added a new table
Step 5 → git add . && git commit -m "Add V10" && git push
Step 6 → GitHub Actions runs automatically — watch the Actions tab
```

---

## ↩️ Rollback Strategy

Flyway does not support automatic rollbacks. The correct pattern is always a new forward migration:

```
V8__add_temp_column.sql    ← the mistake
V9__remove_temp_column.sql ← the fix as a new migration
```

Every rollback is tracked in Git, reviewed in a PR, tested in CI, and fully auditable.
**Never delete or edit an already-applied migration file** — Flyway checksums every file and will refuse to run if one has changed.

---

## 🔁 Environment Flow

```
LOCAL (docker-compose)     → fast iteration, safe to experiment
        ↓
CI TEST DB (GitHub Actions) → clean DB every push, validates everything
        ↓  only if tests pass
KUBERNETES (Minikube)       → staging-like, migrations as K8s Job
        ↓  after verification
TERRAFORM DATABASE          → reproducible infra from code, port 5433
```

---

## ✅ Setup Checklist

```
PHASE 1 — LOCAL SETUP
[ ] Docker Desktop installed and running
[ ] docker-compose.yml created
[ ] docker compose up -d succeeds
[ ] docker ps shows myapp_db running

PHASE 2 — MIGRATIONS (9 files)
[ ] V1__create_users.sql
[ ] V2__create_products.sql
[ ] V3__create_orders.sql
[ ] V4__add_phone_to_users.sql
[ ] V5__add_foreign_keys.sql
[ ] V6__add_indexes.sql
[ ] V7__add_status_to_orders.sql
[ ] V8__add_temp_column.sql
[ ] V9__remove_temp_column.sql
[ ] Flyway runs successfully locally
[ ] \dt shows users, products, orders tables

PHASE 3 — VERSION CONTROL
[ ] Git initialized
[ ] GitHub repo created (public)
[ ] All files pushed to main

PHASE 4 — CI/CD
[ ] .github/workflows/ci.yml created
[ ] tests/verify_schema.sql created
[ ] Pushed to GitHub
[ ] GitHub Actions shows green checkmark ✅

PHASE 5 — KUBERNETES
[ ] Minikube installed
[ ] kubectl installed
[ ] minikube start works
[ ] k8s/postgres.yml applied — pod Running
[ ] k8s/flyway-job.yml applied — Job COMPLETIONS 1/1
[ ] kubectl logs shows successful migration
[ ] \dt inside cluster shows all tables

PHASE 6 — TERRAFORM
[ ] Terraform installed
[ ] terraform/main.tf created
[ ] terraform/variables.tf created
[ ] terraform/outputs.tf created
[ ] terraform init succeeds
[ ] terraform apply creates container
[ ] Flyway runs against port 5433 successfully

PHASE 7 — FINAL
[ ] verify_schema.sql checks all tables and columns
[ ] All 9 migration files committed
[ ] README.md complete
[ ] Screenshots taken and added
[ ] GitHub Actions green on latest commit
[ ] Can explain every tool and why it is used
```

---

## 🎓 Key Learnings

| Concept | Demonstrated by |
|---------|----------------|
| Database as Code | Versioned SQL files in Git — no manual commands |
| Migration versioning | Flyway tracks history, applies in order, once only |
| CI/CD for databases | GitHub Actions validates every schema change |
| Container orchestration | Kubernetes manages DB lifecycle and runs migrations as Jobs |
| Infrastructure as Code | Terraform provisions environments reproducibly |
| Fail-fast testing | Bad migrations caught in CI, never reach production |
| Rollback patterns | Forward-only migrations — every fix is tracked |
| Production patterns | K8s Jobs, initContainers, PVCs — same stack as Netflix and Uber |

---

## 📸 Screenshots to Add

After completing the project, take these screenshots and save in `screenshots/` folder:

1. `01-github-actions-pass.png` — Green checkmark in Actions tab
2. `02-kubectl-get-pods.png` — Pods showing Running status
3. `03-flyway-job-logs.png` — Successful migration logs from K8s
4. `04-terraform-apply.png` — terraform apply output
5. `05-psql-tables.png` — `\dt` showing all tables

---

## 👤 Author

**Pandu** — complete DevOps project demonstrating the full database management lifecycle.

---

> *"Every database change in this project goes through version control, automated testing,
> and infrastructure-as-code provisioning — the same workflow used in production at
> companies like Netflix, Uber, and Spotify."*
