# Domain Model

## ID Strategy

- Internal IDs are integers (bigserial).
- Entities exposed in public URLs use a ULID column (`ulid`, varchar(26), unique index) generated in the application layer. User is excluded — its profile `name` serves as the public identifier instead.

## Enum Strategy

PostgreSQL native ENUM types are not used due to ROM.rb limitations (no schema DSL, `.in()` filtering unsupported). Use `varchar + CHECK` constraint instead.

## Entities

### User

| Field | Type | Notes |
|---|---|---|
| id | bigserial PK | |
| name | string | unique; used as URL slug (e.g. `/@sakuro/profile`) |

A single guest User record (`name: "guest"`) exists and is shared by all unauthenticated operations.

### UserProfile

Public-facing identity information.

| Field | Type | Notes |
|---|---|---|
| id | bigserial PK | |
| user_id | FK → User (1:1) | |
| display_name | string | nullable; human-readable name shown in the UI |
| avatar_s3_key | string | nullable; S3 key for the user's avatar image |
| created_at | timestamp | |

### UserPreference

Private per-user app behavior settings.

| Field | Type | Notes |
|---|---|---|
| id | bigserial PK | |
| user_id | FK → User (1:1) | |
| timezone | string | IANA timezone identifier; defaults to `"UTC"` |
| locale | string | nullable; BCP 47 language tag (e.g. `"ja"`, `"en-US"`); NULL = use browser default |

### Credential

Holds authentication credentials for a User. Separated from UserProfile to allow multiple authentication methods (password, OAuth/SSO, etc.) per user in the future.

| Field | Type | Notes |
|---|---|---|
| id | bigserial PK | |
| user_id | FK → User | |
| provider | string | e.g. `"password"`, `"google"`, `"github"` |
| uid | string | identifier within the provider (e.g. email for password auth) |
| data | JSONB | provider-specific data (see examples below) |
| created_at | timestamp | |

Unique constraint: `(provider, uid)`

`uid` is kept as a dedicated column to support indexed lookups and the unique constraint. Provider-specific data varies by type and is stored in `data`:

```json
// provider: "password"
{ "password_digest": "..." }

// provider: "google" (example)
{ "access_token": "...", "refresh_token": "...", "expires_at": "..." }
```

### Map

Represents a Factorio game world. One map can have multiple generations.

| Field | Type | Notes |
|---|---|---|
| id | bigserial PK | |
| ulid | varchar(26) | unique; used in public URLs |
| user_id | FK → User | |
| mapshot_map_id | string | `map_id` from mapshot.json |
| savename | string | `savename` from mapshot.json (may be empty) |
| name | string | nullable; user-defined display name (future use) |
| created_at | timestamp | |

Unique constraint: `(user_id, mapshot_map_id)`

Display name priority: `name` → `savename` (if not empty) → `mapshot_map_id`

#### Map creation logic

When a generation is uploaded:
- Look up Map by `(user_id, mapshot_map_id)`
- If not found: create Map, then create Generation linked to it
- If found: create Generation linked to the existing Map

### Generation

A snapshot of a map at a specific point in game time.

| Field | Type | Notes |
|---|---|---|
| id | bigserial PK | |
| ulid | varchar(26) | unique; used in public URLs |
| map_id | FK → Map | |
| mapshot_unique_id | string | `unique_id` from mapshot.json |
| tick | bigint | `tick` from mapshot.json |
| metadata_s3_key | string | S3 path to mapshot.json |
| created_at | timestamp | |

Unique constraint: `(map_id, mapshot_unique_id)`

### Upload

Tracks the upload progress of a generation's image files.

| Field | Type | Notes |
|---|---|---|
| id | bigserial PK | |
| ulid | varchar(26) | unique; referenced by client during upload |
| generation_id | FK → Generation (1:1) | |
| status | enum: pending\|complete\|failed | |
| total_image_count | integer | nullable; set when known |
| created_at | timestamp | |
| completed_at | timestamp | nullable |

A Generation is not shown to viewers until its Upload is `complete`.

## Out of scope for persistence

The following data exists only in mapshot.json stored on S3 and is read by the frontend directly:

- Surface (name, bounds, zoom levels, tile size)
- Station (name, position)
- Player positions
- MOD list and game version
