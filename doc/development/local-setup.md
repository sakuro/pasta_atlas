# Local Development

## Overview

Local development uses Docker-based substitutes for AWS services. No AWS account or credentials are needed.

| Production | Local substitute |
|---|---|
| S3 | Floci (S3-compatible emulator, port 4566) |
| RDS (PostgreSQL) | Floci RDS (PostgreSQL container started by Floci, proxy port 7001) |
| CloudFront | Floci (images served directly from `http://localhost:4566`) |
| SSM Parameter Store | `.env.development.local` |

## Prerequisites

- [mise](https://mise.jdx.dev/) — manages Ruby, Node.js (with npm), Terraform, the AWS CLI, the PostgreSQL client tools and other tools; `mise install` installs the versions in `mise.toml`, so no global Node.js is needed. `hanami db` runs `psql` and `pg_dump` from the `PATH`, and `bin/dev` uses `pg_isready`; all three come from the `postgres` entry of `mise.toml`
- Docker

`mise.toml` pins every tool to an exact version. Renovate updates the pins, and both Renovate (`minimumReleaseAge`) and mise (`minimum_release_age`) skip releases younger than three days.

## First-time setup

### 1. Add AWS profile

Add the following profile to `~/.aws/config`:

```ini
[profile pasta-atlas-local]
region = ap-northeast-1
aws_access_key_id = dummy
aws_secret_access_key = dummy
```

This provides dummy credentials and region for Floci. No real AWS account is needed. `.env.development` selects the profile through `AWS_PROFILE`, and both Terraform and `bin/dev` (the `wait-floci` task) use it.

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
- `pasta-atlas-local` RDS instance (PostgreSQL 18, master user `pasta_atlas`)

The bucket's CORS rule must allow `POST` because the browser uploads tiles with presigned POSTs (see [Upload Flow](../architecture/upload-flow.md)). After changing `s3.tf` or `sqs.tf`, run `terraform apply` again.

Floci starts the PostgreSQL container through the Docker socket and keeps its data in a Docker volume of its own, named `floci-aws-rds-*`. `docker compose down -v` does not remove that volume, so remove it with `docker volume rm` to reset the database.

Floci keeps its other data in the `floci_data` volume, while the Terraform state (`terraform.tfstate`) is a gitignored local file. If the state file is missing but the volume still has the resources, `terraform apply` fails because the bucket and queue already exist. Either import them:

```bash
cd terraform/environments/local
terraform import aws_s3_bucket.mapshots pasta-atlas-local-mapshots
terraform import aws_sqs_queue.s3_cleanup http://localhost:4566/000000000000/pasta-atlas-local-s3-cleanup
terraform apply
```

or discard the Floci data and start over (this also removes uploaded maps):

```bash
docker compose down
docker volume rm pasta_atlas_floci_data
docker compose up -d
terraform apply
```

If `AWS_ENDPOINT_URL` points at Floci in your shell, `terraform` against real AWS (`environments/production`) must run with it unset.

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

Starts all services concurrently via mise. The web server and the queue worker first wait until the RDS instance accepts connections (the `wait-postgres` task), and the queue worker also waits until Floci serves its queue (`wait-floci`):

| Process | Command |
|---|---|
| Hanami web server | `bundle exec hanami server` |
| Asset watch (esbuild) | `bundle exec hanami assets watch` |
| Frontend watch (Vite) | `npm run dev:frontend` |
| Docker Compose (Floci) | `docker compose up` |
| SQS queue worker (S3 cleanup) | `bundle exec rake s3:process_queues` |

Production runs the same message handling in Lambda functions triggered by SQS (see [Lambda](../operations/lambda.md)).

Access the app at **http://localhost:2300**.

## Environment files

mise loads env files in this order for development; later files override earlier ones:

```
.env                    # shared values, if present
.env.development        # dev defaults (committed)
.env.development.local  # local overrides (gitignored)
.env.local              # any other local overrides
```

`.env.development` contains working dummy values for all settings except OAuth credentials. `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`, `DISCORD_CLIENT_ID`, `DISCORD_CLIENT_SECRET`, and `STEAM_WEB_API_KEY` need real values and belong in `.env.development.local`.

For tests, `.env.test` provides all dummy values and no additional configuration is needed. Override via `.env.test.local` if necessary.

## Running the tests

```bash
bundle exec rake                 # RSpec and RuboCop
npm run type-check
npm run lint:frontend
npm run test:frontend -- --run   # without --run, Vitest stays in watch mode
```

Request specs need compiled assets (`bundle exec hanami assets compile`) and a prepared test database (`HANAMI_ENV=test bundle exec hanami db structure load` and `db seed`); CI does both before running the specs.
