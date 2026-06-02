# API Endpoints

Images and mapshot.json are served directly via CloudFront, not through the application server.

Presigned PUT URLs are generated locally by the AWS SDK (no S3 API call). The presigned_urls endpoint does make one S3 ListObjectsV2 call to filter already-uploaded files.

---

## Auth

Authentication uses OmniAuth. GitHub, Discord, and Steam OAuth are supported.

### GET /auth/github/callback

OmniAuth GitHub OAuth callback. On success, either sets `session[:user_id]` and redirects to `/` (existing user), or stores OAuth data in `session[:pending_auth]` and redirects to `/auth/register` (new user).

### GET /auth/discord/callback

OmniAuth Discord OAuth callback. Same behavior as the GitHub callback.

### POST /auth/steam/callback

OmniAuth Steam OAuth callback. Same behavior as the GitHub callback.

### GET /auth/failure

Renders the SPA shell with a 400 status. OmniAuth redirects here on failure.

### POST /auth/register

Creates a new User, UserProfile, UserPreference, and Credential. Validates username (max 15 chars, alphanumeric + `-_`, must start and end with alphanumeric, reserved names `guest`/`api`/`admin` are rejected). Requires `session[:pending_auth]`.

**Request params:**

| Field | Notes |
|---|---|
| `name` | New username |
| `timezone` | IANA timezone identifier |
| `terms` | Must be `"1"` (terms acceptance) |

**Response `200 OK`:**

```json
{ "redirect_to": "/" }
```

The SPA navigates to the returned path on success.

**Error responses:**

| Status | Body | Condition |
|---|---|---|
| `403 Forbidden` | — | No `session[:pending_auth]` |
| `422 Unprocessable Entity` | `{"error": "error-terms-required"}` | Terms not accepted |
| `422 Unprocessable Entity` | `{"error": "<key>"}` | Invalid username |

### DELETE /auth/session

Clears `session[:user_id]`. Redirects to `/`.

---

### GET /api/v1/auth/current

Returns the current user and preferences. Used by the SPA on load to initialize `AuthContext`.

**Response `200 OK` (logged in):**

```json
{
  "user": {
    "name": "sakuro",
    "display_name": "OZAWA Sakuro",
    "avatar_url": "https://cdn.example.com/avatars/42/01HXY....jpg"
  },
  "preferences": {
    "locale": "ja",
    "timezone": "Asia/Tokyo",
    "relative_timestamps": false
  }
}
```

**Response `200 OK` (guest):**

```json
{
  "user": null,
  "preferences": { "locale": null, "timezone": "UTC", "relative_timestamps": false }
}
```

### GET /api/v1/auth/registration

Returns pending OAuth data for the registration form. Requires `session[:pending_auth]`.

**Response `200 OK`:**

```json
{ "provider": "github", "login_name": "sakuro" }
```

**Error responses:**

| Status | Condition |
|---|---|
| `401 Unauthorized` | No `session[:pending_auth]` |

---

## User

### GET /api/v1/users/:name

Returns public user info.

**Response `200 OK`:**

```json
{
  "user": {
    "name": "sakuro",
    "display_name": "OZAWA Sakuro",
    "avatar_url": "https://cdn.example.com/avatars/42/01HXY....jpg"
  }
}
```

**Error responses:**

| Status | Condition |
|---|---|
| `403 Forbidden` | User is the guest account |
| `404 Not Found` | User not found |

### GET /api/v1/users/:user_name/profile

Returns the user's profile. Authenticated, own profile only.

**Response `200 OK`:**

```json
{
  "user_name": "sakuro",
  "display_name": "OZAWA Sakuro",
  "avatar_url": "https://cdn.example.com/avatars/42/01HXY....jpg"
}
```

**Error responses:**

| Status | Condition |
|---|---|
| `401 Unauthorized` | Not logged in |
| `403 Forbidden` | Not own profile |

### PATCH /api/v1/users/:user_name/profile

Updates `display_name` (and optionally `avatar_s3_key`). Authenticated, own profile only.

**Request params:**

| Field | Notes |
|---|---|
| `display_name` | Max 64 grapheme clusters; no leading/trailing whitespace or control characters |
| `avatar_s3_key` | Optional; S3 key under `avatars/{user_id}/` |

**Response `200 OK`:**

```json
{ "display_name": "OZAWA Sakuro", "avatar_url": "https://cdn.example.com/..." }
```

**Error responses:**

| Status | Condition |
|---|---|
| `401 Unauthorized` | Not logged in |
| `403 Forbidden` | Not own profile |
| `422 Unprocessable Entity` | Validation error |

### GET /api/v1/users/:user_name/preferences

Returns the user's preferences. Authenticated, own profile only.

**Response `200 OK`:**

```json
{
  "timezone": "Asia/Tokyo",
  "timezone_identifiers": ["Africa/Abidjan", "..."],
  "locale": "ja",
  "relative_timestamps": false
}
```

### PATCH /api/v1/users/:user_name/preferences

Updates timezone, locale, and relative_timestamps. Authenticated, own profile only.

**Request params:**

| Field | Notes |
|---|---|
| `timezone` | IANA timezone identifier (e.g. `"Asia/Tokyo"`); defaults to `"UTC"` if invalid |
| `locale` | BCP 47 language tag (e.g. `"ja"`); empty = use browser locale |
| `relative_timestamps` | `"true"` or `"false"` |

**Response `200 OK`:**

```json
{ "locale": "ja" }
```

**Error responses:**

| Status | Condition |
|---|---|
| `401 Unauthorized` | Not logged in |
| `403 Forbidden` | Not own profile |

### PATCH /api/v1/users/:user_name/avatar

Sets `avatar_s3_key` on the UserProfile. The S3 key must be under `avatars/{user_id}/`. Authenticated, own profile only.

**Request params:**

| Field | Notes |
|---|---|
| `s3_key` | S3 key under `avatars/{user_id}/` |

**Response:** `204 No Content`

**Error responses:**

| Status | Condition |
|---|---|
| `403 Forbidden` | Not authenticated or not own profile |
| `422 Unprocessable Entity` | S3 key not under `avatars/{user_id}/` |

### DELETE /api/v1/users/:user_name/avatar

Clears `avatar_s3_key`. Authenticated, own profile only.

**Response:** `204 No Content`

### GET /api/v1/users/:user_name/credentials

Returns linked OAuth providers. Authenticated, own profile only.

**Response `200 OK`:**

```json
{
  "providers": ["discord", "github", "steam"],
  "connected_providers": ["github"]
}
```

### DELETE /api/v1/users/:user_name/credentials/:provider

Unlinks the OAuth credential for the given provider. Supported providers: `github`, `discord`, `steam`. Authenticated, own profile only.

**Response:** `204 No Content`

**Error responses:**

| Status | Body | Condition |
|---|---|---|
| `403 Forbidden` | — | Not authenticated or not own profile |
| `404 Not Found` | — | Provider not in the allowed list |
| `422 Unprocessable Entity` | `{"error": "error-credential-last"}` | Cannot unlink the last credential |

### POST /api/v1/users/:user_name/profile/avatar_presigned_url

Issues a presigned S3 PUT URL for an avatar image. Authenticated, own profile only.

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
| `403 Forbidden` | Not authenticated or not own profile |
| `422 Unprocessable Entity` | Unsupported content type |

### GET /api/v1/users/:user_name/maps

Returns recent maps uploaded by this user.

**Response `200 OK`:**

```json
{
  "maps": [
    {
      "ulid": "01HXYZ...",
      "display_name": "my-save",
      "user_name": "sakuro",
      "author_display_name": "OZAWA Sakuro",
      "author_avatar_url": "https://cdn.example.com/...",
      "thumbnail_url": "https://cdn.example.com/...",
      "metadata_url": "https://cdn.example.com/.../mapshot.json",
      "updated_at": "2026-04-26T01:23:45Z"
    }
  ]
}
```

**Error responses:**

| Status | Condition |
|---|---|
| `404 Not Found` | User not found or is the guest account |

### DELETE /api/v1/users/:user_name

Deletes the user account, clears the session, and returns a redirect target. Authenticated, own account only.

**Request params:**

| Field | Notes |
|---|---|
| `confirm_user_name` | Must match `:user_name` |

**Response `200 OK`:**

```json
{ "redirect_to": "/" }
```

**Error responses:**

| Status | Condition |
|---|---|
| `400 Bad Request` | `confirm_user_name` does not match |
| `401 Unauthorized` | Not logged in |
| `403 Forbidden` | Not own account |

---

## Maps

### GET /api/v1/maps

Paginated list of maps with at least one `complete` generation, ordered by most recent generation upload.

**Query params:**

| Param | Notes |
|---|---|
| `page` | Page number (default: 1) |

**Response `200 OK`:**

```json
{
  "maps": [
    {
      "ulid": "01HXYZ...",
      "display_name": "my-save",
      "user_name": "sakuro",
      "author_display_name": "OZAWA Sakuro",
      "author_avatar_url": "https://cdn.example.com/...",
      "thumbnail_url": "https://cdn.example.com/...",
      "metadata_url": "https://cdn.example.com/.../mapshot.json",
      "updated_at": "2026-04-26T01:23:45Z"
    }
  ],
  "page": 1,
  "per_page": 20,
  "total": 42
}
```

### GET /api/v1/maps/lookup

Looks up a map by `mapshot_map_id` for the current user (guest or logged in).

**Query params:**

| Param | Notes |
|---|---|
| `mapshot_map_id` | mapshot internal map identifier |

**Response `200 OK`:**

```json
{ "name": "my-save" }
```

**Error responses:**

| Status | Condition |
|---|---|
| `404 Not Found` | No map found for this user + mapshot_map_id |

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

### PATCH /api/v1/maps/:ulid/name

Updates the display name of a map. Authenticated, own map only.

**Request params:**

| Field | Notes |
|---|---|
| `name` | New display name |

**Response `200 OK`:**

```json
{ "display_name": "new-name" }
```

**Error responses:**

| Status | Condition |
|---|---|
| `401 Unauthorized` | Not logged in |
| `403 Forbidden` | Not own map |
| `404 Not Found` | Map not found |
| `422 Unprocessable Entity` | Validation error |

### POST /api/v1/maps/:ulid/deletion_requests

Requests deletion of a map. Authenticated, own map only. Redirects to `/` on success.

**Error responses:**

| Status | Condition |
|---|---|
| `401 Unauthorized` | Not logged in |
| `403 Forbidden` | Not own map |
| `404 Not Found` | Map not found |

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

---

## Pages

### GET /api/v1/pages/:slug

Returns HTML content for a static page. The content is locale-negotiated based on the `Accept-Language` request header.

Supported slugs: `about`, `privacy`, `terms`.

**Response `200 OK`:**

```json
{ "content": "<h1>About</h1>..." }
```

**Error responses:**

| Status | Condition |
|---|---|
| `404 Not Found` | Unknown slug |
