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
    user/            # Profile view/edit, preferences, avatar management, credential management
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

## Action–Operation contract

### Operation

Operations use `Dry::Operation`. The `call` method runs inside `steps`, which wraps the return value in `Success` automatically via `catching_failure { Success(block.call) }`.

- The last expression in `call` must be a **raw value** — never wrap it in `Success`
- Intermediate results are obtained via `step`; a `Failure` from `step` short-circuits `call`
- Private helpers return `Success`/`Failure`; `call` itself never calls `return Failure(...)`
- Auth/authz failures use Rack-standard symbols: `:forbidden`, `:unauthorized`, `:not_found`

```ruby
def call(user_id:, user_name:)
  user = step verify_ownership.call(user_id:, user_name:)
  repo.update(user.id, ...)   # raw return — steps wraps this in Success
end

private def validate(x)
  x.valid? ? Success(x) : Failure(:unprocessable_entity)
end
```

### Action

Actions handle HTTP concerns only. Auth/authz is delegated to Operations.

- Pass `current_user_id(request)` directly to the Operation; do not check login state in Actions
- Hanami's `halt` accepts Rack-standard symbols, so Operation failures map directly: `:forbidden` → 403, `:unauthorized` → 401, `:not_found` → 404

```ruby
result = some_operation.call(user_id: current_user_id(request), ...)
case result
in Failure(status); halt status
in Success(value);  ...
end
```

## Why not slices

Introducing a `web` slice would place repos and operations in the app container while actions live in the slice container. Hanami does not share app container components with slices by default, requiring explicit enumeration of shared keys — a maintenance burden that outweighs the encapsulation benefit at the current scale.

## When to introduce slices

| Slice | Purpose | Trigger to add |
|---|---|---|
| `admin` | Administrative interface | When admin tooling is needed |
