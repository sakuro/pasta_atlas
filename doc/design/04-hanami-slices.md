# Hanami Slice Structure

## Overview

`app/` holds shared domain logic. `slices/` holds delivery-layer code organized by concern.

## Current implementation

```
app/
  relations/       # ROM relations (DB table mappings)
  repos/           # repositories
  operations/      # use cases (orchestrate repos and services)
  services/        # external service adapters (S3, etc.)

slices/
  web/             # Server-rendered HTML pages
    actions/
      maps/
        index.rb   # GET  /maps
        show.rb    # GET  /maps/:ulid
    views/
      maps/
        index.rb
        show.rb
    templates/
      maps/
        index.html.erb
        show.html.erb
      layouts/
        application.html.erb

  api/             # REST API for client-side islands
    actions/
      maps/
        show.rb    # GET  /api/v1/maps/:ulid
      uploads/
        create.rb                   # POST  /api/v1/uploads
        update.rb                   # PATCH /api/v1/uploads/:ulid
        presigned_urls/
          create.rb                 # POST  /api/v1/uploads/:ulid/presigned_urls
```

## Future slices

| Slice | Purpose | Trigger to add |
|---|---|---|
| `auth` | User registration, login, OAuth callbacks, password reset | When user authentication is implemented |
| `admin` | Administrative interface | When admin tooling is needed |

### Notes on `auth` slice

Authentication concerns are intentionally kept out of `api`. The `api` slice only inspects whether a session exists — it does not perform authentication logic itself.

OAuth callback routing (e.g. `/auth/google/callback`) and session management require a different middleware stack from the REST API, making a dedicated slice the right boundary.

## Responsibility split

| Layer | Location | Examples |
|---|---|---|
| HTML delivery | `slices/web/actions/` | Render server-side pages |
| HTML templates | `slices/web/templates/` | ERB templates and layouts |
| View logic | `slices/web/views/` | Hanami::View classes; expose data to templates |
| JSON delivery | `slices/api/actions/` | Parse request, call operation, render JSON |
| Use cases | `app/operations/` | Create map, start upload, issue presigned URLs |
| Data access | `app/repos/` | Find/persist domain entities |
| External services | `app/services/` | S3 presigned URL generation, CloudFront URL building |
| DB mapping | `app/relations/` | ROM relation definitions |
