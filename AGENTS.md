# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Overview

pasta_atlas is a Hanami 2.3 (Ruby) web application for viewing screenshots captured by the Factorio MOD "mapshot". Users upload mapshot tile sets to S3; the app stores metadata in PostgreSQL and serves a SolidJS-based map viewer.

## Commands

### Backend (Ruby)

```bash
bundle exec rake          # Run all tests + RuboCop (default)
bundle exec rake spec     # Run all RSpec tests
bundle exec rspec path/to/spec.rb:LINE  # Run a single test
bundle exec rake rubocop  # Run RuboCop linter
bundle exec rake rubocop:autocorrect    # Auto-fix safe offenses
```

### Frontend (TypeScript/SolidJS)

```bash
npm run build:islands     # Production build
npm run dev:islands       # Watch mode for development
npm run type-check        # TypeScript type checking
npm run lint:frontend     # ESLint on .ts/.tsx files
npm run test:frontend     # Run Vitest tests
```

### Development server

```bash
bin/dev   # Start all dev services via mise: Hanami, Vite watch, PostgreSQL (Docker Compose), and floci (AWS S3 emulator)
```

## Architecture

### Request lifecycle

HTTP request → **Action** (`app/actions/`) → **Operation** (`app/operations/`) → **Repo** (`app/repos/`) → **Relation** (`app/relations/`) → PostgreSQL

Actions handle HTTP concerns (params, session, response codes). Operations contain business logic using `Dry::Operation` with `Success`/`Failure` monads. Repos abstract DB access via ROM/Sequel. Structs (`app/structs/`) are immutable value objects returned from the DB layer.

### Key base classes

- `app/action.rb` — base action; provides `json_response`, `current_user_id`, shared Deps
- `app/operation.rb` — base operation; includes `Dry::Monads[:result]`
- `app/db/repo.rb`, `app/db/relation.rb`, `app/db/struct.rb` — ROM wrappers

### Domain model

- **Map** — a Factorio world tracked by `mapshot_map_id` (unique per user); ULID primary key
- **Generation** — a snapshot of a Map at a given game tick; references S3 `metadata_s3_key` (mapshot.json)
- **Upload** — tracks a tile-image upload session for a Generation (status: pending/complete/failed)
- **User / UserProfile / Credential** — account, display info, OAuth credential

### Authentication

Currently only GitHub OAuth is supported, though other providers may be added. On first login, `session[:pending_auth]` holds OAuth data until the user chooses a username. After login, `session[:user_id]` is set. No session cookie exists for unauthenticated visitors. A special "guest" User is used when no session is present.

### S3 integration

The server issues presigned URLs; the frontend uploads tile images directly to S3. CloudFront serves the images. floci (AWS S3 emulator) is used in development.

### Frontend

SolidJS islands live in `frontend/islands/`. They are bundled by Vite into `public/assets/islands/` and loaded via `<script>` tags in ERB templates. Bulma CSS + FontAwesome for styling.

## Design documents

Detailed design documents are in `doc/design/`:

| # | Document |
|---|---|
| 01 | [Domain Model](doc/design/01-domain-model.md) |
| 02 | [DB Schema](doc/design/02-db-schema.md) |
| 03 | [API Endpoints](doc/design/03-api-endpoints.md) |
| 04 | [Application Structure](doc/design/04-application-structure.md) |
| 05 | [Frontend Components](doc/design/05-frontend-components.md) |
| 06 | [Upload Flow](doc/design/06-upload-flow.md) |
| 07 | [Code Quality](doc/design/07-code-quality.md) |
| 08 | [Project Structure](doc/design/08-project-structure.md) |
| 09 | [Frontend Styling](doc/design/09-frontend-styling.md) |
| 10 | [Infrastructure](doc/design/10-infrastructure.md) |
| 11 | [Local Development](doc/design/11-local-development.md) |
| 12 | [Factorio Rich Text](doc/design/12-rich-text.md) |
| 13 | [Comments](doc/design/13-comments.md) |
