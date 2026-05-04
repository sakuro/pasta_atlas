# PastaAtlas

A web application for browsing Factorio map screenshots captured by the [mapshot](https://github.com/Palats/mapshot) mod. Users upload tile sets to S3; the app stores metadata in PostgreSQL and serves an interactive map viewer built with SolidJS and Leaflet.

## Prerequisites

- [mise](https://mise.jdx.dev/) — task runner and tool version manager
- Docker — runs PostgreSQL and the S3 emulator (floci) via Docker Compose
- A GitHub OAuth app — required for authentication

## Setup

### 1. Start backing services

```sh
docker compose up -d
```

This starts PostgreSQL (port 5432) and floci, an S3-compatible local emulator (port 4566).

### 2. Provision local S3 resources

With floci running, apply the Terraform configuration to create the S3 bucket:

```sh
cd terraform/environments/local
terraform init   # first time only
terraform apply
```

### 3. Configure GitHub OAuth

Create a GitHub OAuth app at <https://github.com/settings/applications/new> with the callback URL `http://localhost:2300/auth/github/callback`, then create `.env.development.local`:

```sh
GITHUB_CLIENT_ID=your_client_id
GITHUB_CLIENT_SECRET=your_client_secret
```

All other environment variables have working defaults in `.env.development`.

### 4. Install dependencies and prepare the database

```sh
bin/setup
```

This runs `bundle install`, `npm install`, and `hanami db prepare` (create + migrate + seed).

## Running the development server

```sh
bin/dev
```

This starts four concurrent processes via mise:

| Process | Command | Role |
|---------|---------|------|
| `web` | `bundle exec hanami server` | Hanami app (port 2300) |
| `assets` | `bundle exec hanami assets watch` | CSS/JS asset pipeline |
| `islands` | `npm run dev:islands` | SolidJS island watcher (Vite HMR) |
| `floci` | `docker compose up` | S3 emulator + PostgreSQL |

Open <http://localhost:2300> in a browser.

## Testing

```sh
bundle exec rake        # Run RSpec + RuboCop (default)
bundle exec rake spec   # RSpec only
bundle exec rake rubocop  # RuboCop only
```

Frontend:

```sh
npm run type-check      # TypeScript
npm run lint:frontend   # ESLint
npm run test:frontend   # Vitest
```

## Design documentation

Detailed design documents are in [`doc/design/`](doc/design/).
