# Application Structure

## Overview

`app/` holds all application code. Slices are not used at this stage. `frontend/` holds the SPA source.

## Directory Layout

```
pasta_atlas/
  app/                     # Application code (Hanami)
    action.rb, operation.rb, view.rb   # Base classes
    actions/               # HTTP actions
      auth/                # OAuth callbacks (GitHub, Discord, Steam), failure, registration, session
      spa/                 # SPA shell delivery (shell, map_viewer, user, not_found)
      api/                 # JSON API (auth, maps, pages, uploads, users)
    assets/                # hanami-assets sources: css/, js/, images/, translations/ (.ftl)
    db/                    # ROM base classes (repo, relation, struct)
    middleware/            # Rack middleware (origin_verify, reverse_proxy_fix)
    operations/            # Use cases (maps, uploads, user, registrations, S3 cleanup)
    page_content/          # Static page HTML per locale (about, privacy_policy, terms_of_service)
    relations/             # ROM relations
    repos/                 # Repositories
    resolvers/             # user_resolver, locale_resolver
    structs/               # Immutable value objects (ROM structs)
    templates/             # ERB templates (layouts/app, spa/shell)
    values/                # Non-ROM value objects
    views/                 # Hanami views
  frontend/                # Vite source (SPA)
    app.tsx                # Entry point (routing, providers)
    pages/                 # Page components; map_viewer/ (viewer, leaflet/, richtext/) and user/ (tabs)
    layout/AppLayout.tsx   # Navbar, content area, footer
    components/            # Shared components; upload_modal/ holds the upload dialogs
    contexts/              # AuthContext, ToastContext
    lib/                   # l10n, display-settings, format-ticks, share-url
    factorio-icons/        # Factorio icon assets
  config/                  # Hanami config, routes, db/ (migrations, structure.sql), assets.js
  lambda_function.rb       # Handlers of the SQS and task Lambda functions
  run.sh                   # Starts Puma behind the Lambda Web Adapter
  scripts/                 # Build, invocation and generation scripts
  terraform/               # Infrastructure
  spec/                    # RSpec tests
  doc/                     # Documentation
```

`vite.config.ts`, `tsconfig.json` and a single `package.json` serve both hanami-assets and Vite.

## Responsibility split

| Layer | Location | Examples |
|---|---|---|
| SPA shell delivery | `app/actions/spa/` + `app/views/spa/` | Validate the route (map exists, user exists and is public), set 404 or 403 if needed, render `<div id="app"></div>` |
| JSON delivery | `app/actions/api/` | Parse request, call operation, render JSON |
| Use cases | `app/operations/` | Find or create a map, start an upload, issue presigned POSTs, verify upload batches, issue an avatar presigned POST |
| Data access | `app/repos/` | Find/persist domain entities |
| DB mapping | `app/relations/` | ROM relation definitions |

## Action–Operation contract

### Operation

Operations use `Dry::Operation`. The `call` method runs inside `steps`, which wraps the return value in `Success` automatically via `catching_failure { Success(block.call) }`.

- The last expression in `call` must be a **raw value** — never wrap it in `Success`
- Intermediate results are obtained via `step`; a `Failure` from `step` short-circuits `call`
- Private helpers return `Success`/`Failure`; `call` itself never calls `return Failure(...)`
- Authorization failures use Rack status symbols: `:forbidden`, `:unauthorized`, `:not_found`

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

Actions handle HTTP concerns. Parameter validation (`:bad_request`) and checks that need only the request or session (pending OAuth data, rejecting the guest) stay in the Action; ownership and domain rules belong to Operations.

- Pass `current_user_id(request)` directly to the Operation
- `halt` accepts only status names known to Rack, plus Hanami's `:unprocessable_entity` and `:unprocessable_content`. Any other symbol raises `Hanami::Action::UnknownHttpStatusError` and the client gets a 500.
- Failures that name a status can therefore go straight to `halt`: `:forbidden`, `:unauthorized`, `:not_found`, `:conflict`, `:unprocessable_entity`, `:bad_gateway`. Domain failures (`:incomplete`, `:s3_error`, `[:invalid, error_key]`, …) must be matched by the Action before the generic branch and mapped to a status.

```ruby
case some_operation.call(user_id: current_user_id(request), ...)
in Failure(:incomplete)         then halt :unprocessable_content
in Failure(Symbol => status)    then halt status
in Success(value)               then ...
end
```

Actions under `app/actions/auth/` must write `Dry::Monads::Result::Failure`, because `Auth::Failure` is an action class and shadows the monad.

## Repositories

Repositories are the only code that talks to the database; operations, actions and the seeds go through them.

- `find_*` returns the record or `nil`. The bang version (`find_by_id!`) raises `ROM::TupleCountMismatchError` and is for records that must exist, such as the parent of a foreign key. A caller that can meet an unknown id (a value from the session, for instance) uses the version without the bang.
- Creates, updates and deletes use ROM commands (`command(:create)`, `command(:update)`, `command(:delete)`). A `dataset` is used only for what a command cannot express: `INSERT ... ON CONFLICT` (`find_or_create_by_*`, `create_many`), an atomic increment (`accumulate_verified_bytes`) and aggregates. Each such call says why in a comment. A `find_or_create_by_*` never changes an existing row; changing one is a separate `update_*` call (see `Operations::Maps::FindOrCreate`).
- A query that joins several tables lives in the relation of the table it starts from (`Relations::Uploads#stale_incomplete_rows`); the repository turns the rows into a value object (`Values::StaleUpload`). Listings that need another relation's join (`MapRepo#list_with_complete_generation*`) are the exception.
- `PastaAtlas::SystemUsers` defines the accounts the seeds create (`guest`, `compilatron`) and the reserved names (those two, `api`, `admin`). `config/db/seeds.rb` is idempotent and uses the repositories.

## Why not slices

Introducing a `web` slice would place repos and operations in the app container while actions live in the slice container. Hanami does not share app container components with slices by default, requiring explicit enumeration of shared keys — a maintenance burden that outweighs the encapsulation benefit at the current scale.

## Asset Pipeline

Two build pipelines write to `public/assets/`:

| Pipeline | Tool | Handles |
|---|---|---|
| General assets | hanami-assets (esbuild), configured in `config/assets.js` | `app/assets/`: `js/app.ts` (imports Bulma, FontAwesome and `css/app.css`), images, and the `.ftl` translation files (fingerprinted and listed in `ftl-manifest.json`) |
| SPA bundle | Vite + `@solidjs/vite-plugin` (`npm run build:frontend`, `npm run dev:frontend`) | The single entry `frontend/app.tsx`; it imports the same CSS again, so the bundle emits its own `app.css` |

Hanami serves both from the same origin. The `hanamiViteEntries` plugin in `vite.config.ts` writes `vite-entries.json` with the hashed `app.js` and `app.css` names, and `config/assets.js` merges it into `assets.json` after each hanami-assets build. The `javascript_tag "app"` and `stylesheet_tag "app"` helpers in the layout therefore resolve to the Vite bundle.
