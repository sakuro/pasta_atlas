# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Overview

Pasta Atlas is a Hanami 3.0 (Ruby) web application for viewing screenshots captured by the Factorio mod "mapshot". Users upload mapshot tile sets to S3; the app stores metadata in PostgreSQL and serves a SolidJS-based map viewer.

## Commands

Tasks are mise tasks, one executable script each in `tasks/` (`mise tasks` lists them). Rake keeps only the tasks that need the application, such as `cleanup:*` and `maps:delete` (`bundle exec rake -T`).

```bash
mise run check            # RSpec, RuboCop, type check, ESLint and Vitest
```

### Backend (Ruby)

```bash
mise run spec             # Run all RSpec tests (SPEC=<glob> selects the files)
bundle exec rspec path/to/spec.rb:LINE  # Run a single test
mise run rubocop          # Run RuboCop linter
mise run rubocop:autocorrect          # Auto-fix safe offenses
```

### Frontend (TypeScript/SolidJS)

```bash
mise run frontend:build         # Production build
mise run frontend:type-check    # TypeScript type checking
mise run frontend:lint          # ESLint on .ts/.tsx files
mise run frontend:format        # Prettier on .ts/.tsx files (rewrites them)
mise run frontend:generate-api  # Regenerate frontend/lib/api/gen/ from openapi.yaml
mise run frontend:test          # Run Vitest tests once (--watch keeps watching)
```

### Development server

```bash
pitchfork start --local   # Start the pitchfork.toml daemons: Hanami server, hanami assets watch, Vite watch, Docker Compose (PostgreSQL and the floci AWS emulator), and the SQS cleanup worker (rake s3:process_queues)
pitchfork stop --local    # Stop them
```

Daemon output is stored by pitchfork, not in `log/`. Read it with `pitchfork logs <daemon> -n 100 --no-pager` (`--since 10min` and `--grep` narrow it); `pitchfork list --project` shows their states (without `--project` it lists the daemons of every project).

## Architecture

### Request lifecycle

HTTP request → **Action** (`app/actions/`) → **Operation** (`app/operations/`) → **Repo** (`app/repos/`) → **Relation** (`app/relations/`) → PostgreSQL

Actions handle HTTP concerns (params, session, response codes). The JSON API contract is [openapi.yaml](openapi.yaml); the frontend client is generated from it. Operations contain business logic using `Dry::Operation` with `Success`/`Failure` monads. Repos abstract DB access via ROM/Sequel. Structs (`app/structs/`) are immutable value objects returned from the DB layer.

### Key base classes

- `app/action.rb` — base action; provides `json_response`, `current_user`, `current_user_id` (falls back to the guest user's id), shared Deps
- `app/operation.rb` — base operation; includes `Dry::Monads[:result]`
- `app/db/repo.rb`, `app/db/relation.rb`, `app/db/struct.rb` — ROM wrappers

### Domain model

- **Map** — a Factorio world tracked by `mapshot_map_id` (unique per user); `id` is bigserial primary key, `ulid` is a separate public identifier column
- **Generation** — a snapshot of a Map at a given game tick; references S3 `metadata_s3_key` (mapshot.json)
- **Upload** — tracks a tile-image upload session for a Generation (status pending/complete, or failed in old data, derived from upload events; verification status pending/passed/failed)
- **User / UserProfile / UserPreference / Credential** — account, display info, locale+timezone preferences, OAuth credential

### Authentication

GitHub, Discord and Steam are supported. On first login, `session[:pending_auth]` holds OAuth data until the user chooses a username. After login, `session[:user_id]` is set. No session cookie exists for unauthenticated visitors. A special "guest" User is used when no session is present.

### S3 integration

The server issues presigned POSTs; the frontend uploads tile images directly to S3. CloudFront serves the images. Deleted maps' S3 prefixes are removed asynchronously through an SQS queue (`rake s3:process_queues` in development, a Lambda function in production). floci (AWS emulator) is used in development.

### Frontend

The frontend is a SolidJS SPA. The SPA is bundled by Vite (`frontend/app.tsx`) into `public/assets/`; hanami-assets (esbuild) builds the CSS and JS of the HTML shell. Bulma CSS + FontAwesome for styling.

## Documentation

Documents are in `doc/`; [doc/README.md](doc/README.md) lists them. They are grouped by `architecture/` (how the application works), `operations/` (production) and `development/` (local setup, code quality).
