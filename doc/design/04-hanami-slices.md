# Application Structure

## Overview

`app/` holds all application code. Slices are not used at this stage.

## Current implementation

```
app/
  actions/           # HTTP actions (parse request, call operation, render response)
    uploads/
      create.rb                   # POST  /api/v1/uploads
      update.rb                   # PATCH /api/v1/uploads/:ulid
      presigned_urls/
        create.rb                 # POST  /api/v1/uploads/:ulid/presigned_urls
  relations/         # ROM relations (DB table mappings)
  repos/             # Repositories
  operations/        # Use cases (orchestrate repos and services)
  services/          # External service adapters (S3, etc.)
```

## Responsibility split

| Layer | Location | Examples |
|---|---|---|
| JSON delivery | `app/actions/` | Parse request, call operation, render JSON |
| Use cases | `app/operations/` | Create map, start upload, issue presigned URLs |
| Data access | `app/repos/` | Find/persist domain entities |
| External services | `app/services/` | S3 presigned URL generation, CloudFront URL building |
| DB mapping | `app/relations/` | ROM relation definitions |

## When to introduce slices

| Slice | Purpose | Trigger to add |
|---|---|---|
| `auth` | User registration, login, OAuth callbacks, password reset | When user authentication is implemented |
| `web` | Server-rendered HTML pages | When server-rendered views are needed |
| `admin` | Administrative interface | When admin tooling is needed |

### Notes on `auth` slice

Authentication concerns should be kept separate from the main API actions. OAuth callback routing (e.g. `/auth/google/callback`) and session management require a different middleware stack from the REST API, making a dedicated slice the right boundary.
