# PastaAtlas

A web application for browsing Factorio map screenshots captured by the [mapshot](https://github.com/Palats/mapshot) mod. Users upload tile sets to S3; the app stores metadata in PostgreSQL and serves an interactive map viewer built with SolidJS and Leaflet.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | [Ruby](https://www.ruby-lang.org/) / [Hanami](https://hanamirb.org/) |
| Frontend | [SolidJS](https://www.solidjs.com/) / [Vite](https://vitejs.dev/) |
| Map rendering | [Leaflet](https://leafletjs.com/) |
| CSS | [Bulma](https://bulma.io/) |
| Icons | [Font Awesome](https://fontawesome.com/) |
| Database | PostgreSQL |
| Object storage | AWS S3 (local: [floci](https://floci.io/)) |

## Prerequisites

- [mise](https://mise.en.dev/) — task runner and tool version manager
- Docker — runs PostgreSQL and the S3 emulator (floci) via Docker Compose
- A GitHub OAuth app — required for authentication
- A Discord OAuth app — required for authentication
- A Steam Web API key — required for authentication

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

### 3. Configure OAuth

Create `.env.development.local` with credentials for each provider. All other environment variables have working defaults in `.env.development`.

#### GitHub

Create a GitHub OAuth app at <https://github.com/settings/applications/new> with the callback URL `http://localhost:2300/auth/github/callback`, then add to `.env.development.local`:

```sh
GITHUB_CLIENT_ID=your_client_id
GITHUB_CLIENT_SECRET=your_client_secret
```

#### Discord

Create a Discord OAuth app at <https://discord.com/developers/applications>, add `http://localhost:2300/auth/discord/callback` as a redirect URL, then add to `.env.development.local`:

```sh
DISCORD_CLIENT_ID=your_client_id
DISCORD_CLIENT_SECRET=your_client_secret
```

#### Steam

Obtain a Steam Web API key at <https://steamcommunity.com/dev/apikey>, then add to `.env.development.local`:

```sh
STEAM_WEB_API_KEY=your_api_key
```

### 4. Install dependencies and prepare the database

```sh
bin/setup
```

This runs `bundle install`, `npm install`, and `hanami db prepare` (create + migrate + seed).


## Running the development server

```sh
bin/dev
```

This starts five concurrent processes via mise:

| Process | Command | Role |
|---------|---------|------|
| `web` | `bundle exec hanami server` | Hanami app (port 2300) |
| `assets` | `bundle exec hanami assets watch` | CSS/JS asset pipeline |
| `islands` | `npm run dev:islands` | SolidJS island watcher (Vite HMR) |
| `floci` | `docker compose up` | S3 emulator + PostgreSQL |
| `s3-cleanup-queue-worker` | `bundle exec rake s3:process_cleanup_queue` | S3 deletion queue worker |

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
