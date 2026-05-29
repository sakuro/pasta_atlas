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

### 1. Add AWS profile

Add the following profile to `~/.aws/config`:

```ini
[profile pasta-atlas-local]
region = ap-northeast-1
aws_access_key_id = dummy
aws_secret_access_key = dummy
```

This provides dummy credentials and region for Floci. No real AWS account is needed.

### 2. Start Docker services

```bash
docker compose up -d
```

### 3. Provision local AWS resources

```bash
cd terraform/environments/local
terraform init
terraform apply
cd -
```

This creates the following resources in Floci:

- `pasta-atlas-local-mapshots` S3 bucket
- `pasta-atlas-local-s3-cleanup` SQS queue

### 4. Configure OAuth providers

At least one provider must be configured. Create `.env.development.local` (gitignored) with credentials for the providers you want to use.

#### GitHub

Register a GitHub OAuth App at https://github.com/settings/developers with:

- **Homepage URL**: `http://localhost:2300`
- **Authorization callback URL**: `http://localhost:2300/auth/github/callback`

```
GITHUB_CLIENT_ID=<your client id>
GITHUB_CLIENT_SECRET=<your client secret>
```

#### Discord

Register a Discord application at https://discord.com/developers/applications and add `http://localhost:2300/auth/discord/callback` as a redirect URL.

```
DISCORD_CLIENT_ID=<your client id>
DISCORD_CLIENT_SECRET=<your client secret>
```

#### Steam

Obtain a Steam Web API key at https://steamcommunity.com/dev/apikey.

```
STEAM_WEB_API_KEY=<your api key>
```

Without at least one provider configured, the app starts but login is unavailable.

### 5. Install dependencies and prepare the database

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
| S3 cleanup queue worker | `bundle exec rake s3:process_cleanup_queue` |

Access the app at **http://localhost:2300**.

## Environment files

mise loads env files in this order for development:

```
.env                    # base defaults (committed)
.env.development        # dev defaults (committed)
.env.development.local  # local overrides (gitignored)
.env.local              # any other local overrides (gitignored)
```

`.env.development` contains working dummy values for all settings except OAuth credentials. `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`, `DISCORD_CLIENT_ID`, `DISCORD_CLIENT_SECRET`, and `STEAM_WEB_API_KEY` need real values and belong in `.env.development.local`.

For tests, `.env.test` provides all dummy values and no additional configuration is needed. Override via `.env.test.local` if necessary.
