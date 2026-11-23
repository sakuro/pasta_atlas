# Database Schema

Database: PostgreSQL

## Conventions

- All timestamps use `timestamptz`. Stored internally as UTC.
- Timezone conversion for display is the frontend's responsibility.
- Internal IDs are `bigserial`. Entities exposed in public URLs also have a unique `ulid varchar(26)` column.
- PostgreSQL native ENUM types are not used due to ROM.rb limitations (no schema DSL, `.in()` filtering unsupported). A `text` column with a `CHECK` constraint is used instead.

## Tables

### users

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| name | text | NOT NULL |

Indexes:
- UNIQUE on `name`

### user_profiles

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| user_id | bigint | NOT NULL, REFERENCES users(id) ON DELETE CASCADE |
| display_name | text | |
| avatar_s3_key | text | |
| created_at | timestamptz | NOT NULL DEFAULT now() |

Indexes:
- UNIQUE on `user_id`

### user_preferences

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| user_id | bigint | NOT NULL, REFERENCES users(id) ON DELETE CASCADE |
| timezone | text | |
| locale | text | |
| relative_timestamps | boolean | NOT NULL DEFAULT false |

Indexes:
- UNIQUE on `user_id`

### credentials

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| user_id | bigint | NOT NULL, REFERENCES users(id) ON DELETE CASCADE |
| provider | text | NOT NULL |
| uid | text | NOT NULL |
| data | jsonb | NOT NULL DEFAULT '{}' |
| created_at | timestamptz | NOT NULL DEFAULT now() |

Indexes:
- UNIQUE on `(provider, uid)`
- INDEX on `user_id`

### maps

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| ulid | varchar(26) | NOT NULL |
| user_id | bigint | NOT NULL, REFERENCES users(id) ON DELETE CASCADE |
| mapshot_map_id | text | NOT NULL |
| savename | text | NOT NULL DEFAULT '' |
| name | text | |
| created_at | timestamptz | NOT NULL DEFAULT now() |

Indexes:
- UNIQUE on `ulid`
- UNIQUE on `(user_id, mapshot_map_id)`
- INDEX on `user_id`

### generations

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| ulid | varchar(26) | NOT NULL |
| map_id | bigint | NOT NULL, REFERENCES maps(id) ON DELETE CASCADE |
| mapshot_unique_id | text | NOT NULL |
| tick | bigint | NOT NULL |
| metadata_s3_key | text | NOT NULL |
| created_at | timestamptz | NOT NULL DEFAULT now() |
| storage_bytes | bigint | |

Indexes:
- UNIQUE on `ulid`
- UNIQUE on `(map_id, mapshot_unique_id)`
- INDEX on `map_id`

### uploads

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| ulid | varchar(26) | NOT NULL |
| generation_id | bigint | NOT NULL, REFERENCES generations(id) ON DELETE CASCADE |
| total_image_count | integer | NOT NULL |
| created_at | timestamptz | NOT NULL DEFAULT now() |
| verification_status | text | NOT NULL DEFAULT 'pending', CHECK (verification_status IN ('pending', 'passed', 'failed')) |
| metadata_bytes | bigint | NOT NULL DEFAULT 0 |
| verified_at | timestamptz | |

Indexes:
- UNIQUE on `ulid`
- UNIQUE on `generation_id`

### upload_verification_keys

The S3 keys expected for an upload. A key is marked verified once the object is confirmed to exist.

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| upload_id | bigint | NOT NULL, REFERENCES uploads(id) ON DELETE CASCADE |
| s3_key | text | NOT NULL |
| verified_at | timestamptz | |
| size_bytes | bigint | |

Indexes:
- UNIQUE on `(upload_id, s3_key)`

### avatar_uploads

The avatar keys issued to a user by `avatar_presigned_post`. Only a key recorded here, unexpired and not consumed, can become the user's avatar; applying it sets `consumed_at`.

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| user_id | bigint | NOT NULL, REFERENCES users(id) ON DELETE CASCADE |
| s3_key | text | NOT NULL |
| content_type | text | NOT NULL |
| expires_at | timestamptz | NOT NULL |
| consumed_at | timestamptz | |
| created_at | timestamptz | NOT NULL, DEFAULT now() |

Indexes:
- UNIQUE on `s3_key`
- on `(user_id, consumed_at)`

Rows are deleted by `cleanup:orphaned_avatars` a day after they expire.

### upload_events

Append-only log of status transitions. Never updated, only inserted.

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| upload_id | bigint | NOT NULL, REFERENCES uploads(id) ON DELETE CASCADE |
| event_type | text | NOT NULL, CHECK (event_type IN ('pending', 'complete', 'failed')) |
| occurred_at | timestamptz | NOT NULL DEFAULT now() |

Indexes:
- INDEX on `upload_id`

## Views

### current_upload_statuses

Returns the latest event per upload, representing the current status.

```sql
CREATE VIEW current_upload_statuses AS
SELECT DISTINCT ON (upload_id)
  upload_id,
  event_type AS status,
  occurred_at
FROM upload_events
ORDER BY upload_id, occurred_at DESC, id DESC;
```

## Cascade policy

| Delete | Cascades to |
|---|---|
| users | user_profiles, user_preferences, credentials, maps, avatar_uploads |
| maps | generations |
| generations | uploads |
| uploads | upload_events, upload_verification_keys |
