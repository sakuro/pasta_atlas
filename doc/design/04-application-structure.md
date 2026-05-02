# Application Structure

## Overview

`app/` holds all application code. Slices are not used at this stage.

## Current implementation

```
app/
  actions/           # HTTP actions (parse request, call operation, render response)
    auth/            # OmniAuth callbacks, registration, session management (namespace mirrors /auth/* paths by convention)
    maps/
      index.rb                    # GET   /
      viewer.rb                   # GET   /@:user_name/maps/:ulid
      show.rb                     # GET   /api/v1/maps/:ulid
    profile/         # Profile view/edit and avatar management
    uploads/
      create.rb                   # POST  /api/v1/uploads
      update.rb                   # PATCH /api/v1/uploads/:ulid
      presigned_urls/
        create.rb                 # POST  /api/v1/uploads/:ulid/presigned_urls
  views/             # Hanami views (HTML rendering)
  templates/         # ERB templates
  relations/         # ROM relations (DB table mappings)
  repos/             # Repositories
  structs/           # Immutable value objects (ROM structs)
  operations/        # Use cases (orchestrate repos, S3, etc.)
```

## Responsibility split

| Layer | Location | Examples |
|---|---|---|
| HTML delivery | `app/actions/` + `app/views/` | Parse request, call operation, render HTML |
| JSON delivery | `app/actions/` | Parse request, call operation, render JSON |
| Use cases | `app/operations/` | Create map, start upload, issue presigned URLs, generate avatar URL |
| Data access | `app/repos/` | Find/persist domain entities |
| DB mapping | `app/relations/` | ROM relation definitions |

## Why not slices

Introducing a `web` slice would place repos and operations in the app container while actions live in the slice container. Hanami does not share app container components with slices by default, requiring explicit enumeration of shared keys — a maintenance burden that outweighs the encapsulation benefit at the current scale.

## When to introduce slices

| Slice | Purpose | Trigger to add |
|---|---|---|
| `admin` | Administrative interface | When admin tooling is needed |
