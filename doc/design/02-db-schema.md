# Database Schema

Database: PostgreSQL

## Conventions

- All timestamps use `timestamptz`. Stored internally as UTC.
- Sequel is configured with `database_timezone = :utc` and `application_timezone = :utc`. Timestamps are always treated as UTC throughout the backend stack.
- Timezone conversion for display is the frontend's responsibility.

## Tables

### users

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| name | varchar | NOT NULL |

Indexes:
- UNIQUE on `name`

### user_profiles

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| user_id | bigint | NOT NULL, REFERENCES users(id) ON DELETE CASCADE |
| display_name | varchar | |
| avatar_s3_key | varchar | |
| created_at | timestamptz | NOT NULL DEFAULT now() |

Indexes:
- UNIQUE on `user_id`

### user_preferences

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| user_id | bigint | NOT NULL, REFERENCES users(id) ON DELETE CASCADE |
| timezone | varchar | NOT NULL DEFAULT 'UTC' |
| locale | varchar | |

Indexes:
- UNIQUE on `user_id`

### credentials

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| user_id | bigint | NOT NULL, REFERENCES users(id) ON DELETE CASCADE |
| provider | varchar | NOT NULL |
| uid | varchar | NOT NULL |
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
| mapshot_map_id | varchar | NOT NULL |
| savename | varchar | NOT NULL DEFAULT '' |
| name | varchar | |
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
| mapshot_unique_id | varchar | NOT NULL |
| tick | bigint | NOT NULL |
| metadata_s3_key | varchar | NOT NULL |
| created_at | timestamptz | NOT NULL DEFAULT now() |
| expires_at | timestamptz | |

Indexes:
- UNIQUE on `ulid`
- UNIQUE on `(map_id, mapshot_unique_id)`
- INDEX on `map_id`
- INDEX on `expires_at`

### uploads

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| ulid | varchar(26) | NOT NULL |
| generation_id | bigint | NOT NULL, REFERENCES generations(id) ON DELETE CASCADE |
| total_image_count | integer | |
| created_at | timestamptz | NOT NULL DEFAULT now() |

Indexes:
- UNIQUE on `ulid`
- UNIQUE on `generation_id`

### upload_events

Append-only log of status transitions. Never updated, only inserted.

| Column | Type | Constraints |
|---|---|---|
| id | bigserial | PRIMARY KEY |
| upload_id | bigint | NOT NULL, REFERENCES uploads(id) ON DELETE CASCADE |
| event_type | varchar | NOT NULL, CHECK (event_type IN ('pending', 'complete', 'failed')) |
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
| users | user_profiles, user_preferences, credentials, maps |
| maps | generations |
| generations | uploads |
| uploads | upload_events |
