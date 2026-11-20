# Domain Model

## ID Strategy

- Internal IDs are integers (bigserial).
- Entities exposed in public URLs use a ULID column (`ulid`, `varchar(26)`, unique index) generated in the application layer. User is excluded — its profile `name` serves as the public identifier instead.

## Enum Strategy

PostgreSQL native ENUM types are not used due to ROM.rb limitations (no schema DSL, `.in()` filtering unsupported). Use a `text` column with a `CHECK` constraint instead.

## Entities

### User

| Field | Type | Notes |
|---|---|---|
| id | bigserial PK | |
| name | string | unique; used as URL slug (e.g. `/@sakuro`) |

The seeds create two system users, `guest` and `compilatron`, and the names `guest`, `api`, `admin` and `compilatron` are reserved. `guest` is shared by all unauthenticated requests and cannot upload, rename or delete maps. System users have no public profile.

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
| timezone | string | nullable; IANA timezone identifier; NULL = use browser default |
| locale | string | nullable; BCP 47 language tag (e.g. `"ja"`, `"en-US"`); NULL = use browser default |
| relative_timestamps | boolean | defaults to `false`; show timestamps as relative time (e.g. "3 hours ago") instead of absolute |

### Credential

Holds an OAuth credential of a User. A user can link several providers.

| Field | Type | Notes |
|---|---|---|
| id | bigserial PK | |
| user_id | FK → User | |
| provider | string | `"github"`, `"discord"` or `"steam"` |
| uid | string | user identifier within the provider |
| data | JSONB | reserved for provider-specific data; currently always `{}` |
| created_at | timestamp | |

Unique constraint: `(provider, uid)`

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
| storage_bytes | bigint | nullable; total size of the tile images, copied from `Upload.verified_bytes` when verification passes |

Unique constraint: `(map_id, mapshot_unique_id)`

### Upload

Tracks an upload session for a generation's image files. Status is derived from the latest UploadEvent; the check that the files reached S3 is tracked in `verification_status`.

| Field | Type | Notes |
|---|---|---|
| id | bigserial PK | |
| ulid | varchar(26) | unique; referenced by client during upload |
| generation_id | FK → Generation (1:1) | |
| total_image_count | integer | number of tile images expected (1–10000) |
| created_at | timestamp | |
| verification_status | enum: pending\|passed\|failed | defaults to `pending` |
| verified_bytes | bigint | sum of the verified object sizes; defaults to 0 |
| verified_at | timestamp | nullable; set when verification passes |

A Generation is not shown to viewers until its Upload's current status is `complete`.

### UploadVerificationKey

One row per S3 key expected for an Upload.

| Field | Type | Notes |
|---|---|---|
| id | bigint PK | |
| upload_id | FK → Upload | |
| s3_key | string | |
| verified_at | timestamp | nullable; set when the object is confirmed to exist |
| size_bytes | bigint | nullable; object size at verification |

Unique constraint: `(upload_id, s3_key)`

An Upload can be completed only when the number of verified keys equals its `total_image_count`.

### UploadEvent

Append-only log of status transitions for an Upload.

| Field | Type | Notes |
|---|---|---|
| id | bigserial PK | |
| upload_id | FK → Upload | |
| event_type | enum: pending\|complete\|failed | |
| occurred_at | timestamp | |

The current status of an Upload is the `event_type` of the latest UploadEvent ordered by `occurred_at DESC`. This is exposed via the `current_upload_statuses` database view.

On Upload creation, a `pending` event is inserted within the same transaction.

## Out of scope for persistence

The following data exists only in mapshot.json stored on S3 and is read by the frontend directly:

- Surface (name, bounds, zoom levels, tile size)
- Station (name, position)
- Player positions
- MOD list and game version
