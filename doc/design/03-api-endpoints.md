# API Endpoints

Images and mapshot.json are served directly via CloudFront, not through the application server.

Presigned PUT URLs are generated locally by the AWS SDK (no S3 API call). The presigned_urls endpoint does make one S3 ListObjectsV2 call to filter already-uploaded files.

---

## Auth

Authentication uses OmniAuth. GitHub and Discord OAuth are supported.

### GET /auth/github/callback

OmniAuth GitHub OAuth callback. On success, either sets `session[:user_id]` and redirects to `/` (existing user), or stores OAuth data in `session[:pending_auth]` and redirects to `/auth/register` (new user).

### GET /auth/discord/callback

OmniAuth Discord OAuth callback. Same behavior as the GitHub callback.

### GET /auth/failure

Displays an auth error page. OmniAuth redirects here on failure.

### GET /auth/register

Displays the username registration form for new users. Requires `session[:pending_auth]`.

### POST /auth/register

Creates a new User, UserProfile, UserPreference, and Credential. Validates username (max 39 chars, alphanumeric + `-_`, reserved names `guest`/`api`/`admin` are rejected). On success, sets `session[:user_id]` and redirects to `/`.

### DELETE /auth/session

Clears `session[:user_id]`. Redirects to `/`.

---

## User

Profile pages are server-rendered HTML. The avatar upload uses a JSON API endpoint for the presigned URL.

### GET /@:user_name

Displays a user's public profile page: display name, avatar, and recent maps.

### PATCH /@:user_name/profile

Updates `display_name`. Authenticated, own profile only.

**Form params:**

| Field | Notes |
|---|---|
| `display_name` | Max 64 grapheme clusters; no whitespace or control characters |

**Error:** Re-renders edit form with validation error message. Redirects to `/@:user_name` on success.

### PATCH /@:user_name/preferences

Updates timezone and locale. Authenticated, own profile only.

**Form params:**

| Field | Notes |
|---|---|
| `timezone` | IANA timezone identifier (e.g. `"Asia/Tokyo"`); defaults to `"UTC"` if invalid |
| `locale` | BCP 47 language tag (e.g. `"ja"`); empty = use browser locale |

**Response:** Redirects to `/@:user_name`.

### PATCH /@:user_name/avatar

Sets `avatar_s3_key` on the UserProfile. The S3 key must be under `avatars/{user_id}/`. Authenticated, own profile only.

**Request body:**

```json
{ "s3_key": "avatars/42/01HXY....jpg" }
```

**Response:** `204 No Content`

**Error responses:**

| Status | Condition |
|---|---|
| `403 Forbidden` | Not authenticated or not own profile |
| `422 Unprocessable Entity` | S3 key not under `avatars/{user_id}/` |

### DELETE /@:user_name/avatar

Clears `avatar_s3_key`. Authenticated, own profile only.

**Response:** `204 No Content`

### DELETE /@:user_name/credentials/:provider

Unlinks the OAuth credential for the given provider. Supported providers: `github`, `discord`. Authenticated, own profile only.

**Response:** Redirects to `/@:user_name#tab-credentials`. Sets a flash error if the credential being removed is the user's last one.

**Error responses:**

| Status | Condition |
|---|---|
| `403 Forbidden` | Not authenticated or not own profile |
| `404 Not Found` | Provider not in the allowed list |

### POST /api/v1/profile/avatar_presigned_url

Issues a presigned S3 PUT URL for an avatar image. Requires authentication.

**Request body:**

```json
{ "content_type": "image/jpeg" }
```

Supported content types: `image/jpeg`, `image/png`, `image/webp`.

**Response `200 OK`:**

```json
{
  "presigned_url": "https://s3.amazonaws.com/bucket/avatars/42/01HXY....jpg?...",
  "s3_key": "avatars/42/01HXY....jpg"
}
```

**Error responses:**

| Status | Condition |
|---|---|
| `403 Forbidden` | Not authenticated |
| `422 Unprocessable Entity` | Unsupported content type |

---

## Maps

### GET /api/v1/maps/:ulid

Map details with all complete generations.

**Response `200 OK`:**

```json
{
  "ulid": "01HXYZ...",
  "display_name": "my-save",
  "owner": { "name": "sakuro" },
  "generations": [
    {
      "ulid": "01HABC...",
      "tick": 29386437,
      "metadata_url": "https://maps.pasta-atlas.layer8.works/sakuro/ae8ec3ab/550f41a9/mapshot.json"
    }
  ]
}
```

`generations` is sorted by `tick` descending. `metadata_url` is the CloudFront URL for the generation's mapshot.json.

**Error responses:**

| Status | Condition |
|---|---|
| `404 Not Found` | Map with given ULID does not exist |

---

## Uploads

### POST /api/v1/uploads

Start an upload session. Creates Map (if new for this user), Generation, and Upload records.

**Request body:**

```json
{
  "metadata": { "...mapshot.json content..." },
  "total_image_count": 42,
  "name": "My Map"
}
```

`name` is optional. When provided, it overrides the display name derived from `mapshot.json` (`name` → `savename` → `mapshot_map_id`).

**Response `201 Created`:**

```json
{
  "ulid": "01HUPLOAD...",
  "map_ulid": "01HXYZ...",
  "generation_ulid": "01HABC..."
}
```

**Error responses:**

| Status | Condition |
|---|---|
| `409 Conflict` | A `complete` upload already exists for this generation |
| `502 Bad Gateway` | S3 write of `mapshot.json` failed; DB records rolled back |

---

### POST /api/v1/uploads/:ulid/presigned_urls

Request presigned S3 PUT URLs for image files. The server checks existing S3 keys (via ListObjectsV2, 1 API call) and returns URLs only for files not yet uploaded. Send the full filename list each time — the server handles filtering.

**Request body:**

```json
{
  "filenames": ["s1zoom_4/tile_0_0.jpg", "s1zoom_4/tile_1_0.jpg", "..."]
}
```

**Response `200 OK`:**

```json
{
  "presigned_urls": {
    "s1zoom_4_0_0.png": "https://s3.amazonaws.com/bucket/...?X-Amz-Signature=...",
    "s1zoom_4_1_0.png": "https://s3.amazonaws.com/bucket/...?X-Amz-Signature=..."
  }
}
```

May be called multiple times with a subset of filenames (e.g. remaining files after partial upload, or after URL expiry).

**Error responses:**

| Status | Condition |
|---|---|
| `404 Not Found` | Upload with given ULID does not exist |
| `422 Unprocessable Entity` | Upload status is `complete` or `failed` |

---

### PATCH /api/v1/uploads/:ulid

Mark an upload as complete or failed.

**Request body:**

```json
{
  "status": "complete"
}
```

**Response `200 OK`:**

```json
{
  "ulid": "01HUPLOAD...",
  "status": "complete",
  "completed_at": "2026-04-26T01:23:45Z"
}
```

**Error responses:**

| Status | Condition |
|---|---|
| `404 Not Found` | Upload with given ULID does not exist |
