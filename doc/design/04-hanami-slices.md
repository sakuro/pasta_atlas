# Application Structure

## Overview

`app/` holds all application code. Slices are not used at this stage.

## Current implementation

```
app/
  actions/           # HTTP actions (parse request, call operation, render response)
    maps/
      index.rb                    # GET   /
      viewer.rb                   # GET   /maps/:ulid
      show.rb                     # GET   /api/v1/maps/:ulid
    uploads/
      create.rb                   # POST  /api/v1/uploads
      update.rb                   # PATCH /api/v1/uploads/:ulid
      presigned_urls/
        create.rb                 # POST  /api/v1/uploads/:ulid/presigned_urls
  views/             # Hanami views (HTML rendering)
  templates/         # ERB templates
  relations/         # ROM relations (DB table mappings)
  repos/             # Repositories
  operations/        # Use cases (orchestrate repos and services)
  services/          # External service adapters (S3, etc.)
```

## Responsibility split

| Layer | Location | Examples |
|---|---|---|
| HTML delivery | `app/actions/` + `app/views/` | Parse request, call operation, render HTML |
| JSON delivery | `app/actions/` | Parse request, call operation, render JSON |
| Use cases | `app/operations/` | Create map, start upload, issue presigned URLs |
| Data access | `app/repos/` | Find/persist domain entities |
| External services | `app/services/` | S3 presigned URL generation, CloudFront URL building |
| DB mapping | `app/relations/` | ROM relation definitions |

## Why not slices

Introducing a `web` slice would place repos and operations in the app container while actions live in the slice container. Hanami does not share app container components with slices by default, requiring explicit enumeration of shared keys — a maintenance burden that outweighs the encapsulation benefit at the current scale.

## When to introduce slices

| Slice | Purpose | Trigger to add |
|---|---|---|
| `auth` | User registration, login, OAuth callbacks, password reset | When user authentication is implemented |
| `admin` | Administrative interface | When admin tooling is needed |

### Notes on `auth` slice

Authentication concerns should be kept separate from the main API actions. OAuth callback routing (e.g. `/auth/google/callback`) and session management require a different middleware stack from the REST API, making a dedicated slice the right boundary.
