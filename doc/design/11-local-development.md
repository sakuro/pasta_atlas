# Local Development

## Overview

Local development uses Docker-based substitutes for AWS services. No AWS account or credentials are needed.

| Production | Local substitute |
|---|---|
| S3 | Floci (S3-compatible emulator, port 4566) |
| RDS (PostgreSQL) | PostgreSQL container (port 5432) |
| CloudFront | Floci (images served directly from `http://localhost:4566`) |
| Secrets Manager | `.env.development.local` |

## Prerequisites

- [mise](https://mise.jdx.dev/) — manages Ruby, Node.js, Terraform, and other tools
- Docker

## First-time setup

### 1. Start Docker services

```bash
docker compose up -d
```

### 2. Provision local S3 bucket

```bash
cd terraform/environments/local
terraform init
terraform apply
cd -
```

This creates the `pasta-atlas-local-mapshots` bucket in Floci.

### 3. Configure GitHub OAuth

Register a GitHub OAuth App at https://github.com/settings/developers with:

- **Homepage URL**: `http://localhost:2300`
- **Authorization callback URL**: `http://localhost:2300/auth/github/callback`

Then create `.env.development.local` (gitignored):

```
GITHUB_CLIENT_ID=<your client id>
GITHUB_CLIENT_SECRET=<your client secret>
```

Without this, the app starts but login is unavailable.

### 4. Install dependencies and prepare the database

```bash
bin/setup
```

This runs `bundle install`, `npm install`, and `hanami db prepare`.

## Starting the dev server

```bash
bin/dev
```

Starts all services concurrently via mise:

| Process | Command |
|---|---|
| Hanami web server | `bundle exec hanami server` |
| Asset watch (esbuild) | `bundle exec hanami assets watch` |
| Island watch (Vite) | `npm run dev:islands` |
| Docker Compose (Floci + PostgreSQL) | `docker compose up` |

Access the app at **http://localhost:2300**.

## Environment files

mise loads env files in this order for development:

```
.env                    # base defaults (committed)
.env.development        # dev defaults (committed)
.env.development.local  # local overrides (gitignored)
.env.local              # any other local overrides (gitignored)
```

`.env.development` contains working dummy values for all settings except GitHub OAuth credentials. Only `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` need real values and belong in `.env.development.local`.

For tests, `.env.test` provides all dummy values and no additional configuration is needed. Override via `.env.test.local` if necessary.
