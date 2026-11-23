# API Endpoints

The JSON endpoints in [openapi.yaml](../../openapi.yaml) are specified there and not repeated here.

## Auth

Authentication uses OmniAuth. GitHub, Discord, and Steam OAuth are supported.

### GET /auth/github/callback

OmniAuth GitHub OAuth callback. If a user is already logged in, the provider is linked to that account and the response redirects to `/@{name}#tab-credentials` (a `error-credential-conflict` flash is set when the credential belongs to another user or linking fails). Otherwise, for an existing credential the session is reset, `session[:user_id]` is set and the response redirects to `/`; for an unknown credential the OAuth data is stored in `session[:pending_auth]` and the response redirects to `/auth/register`. `400 Bad Request` if the OmniAuth data is missing.

### GET /auth/discord/callback

OmniAuth Discord OAuth callback. Same behavior as the GitHub callback.

### POST /auth/steam/callback

OmniAuth Steam OAuth callback. Same behavior as the GitHub callback, but rejected with `400 Bad Request` unless the login was started through `/auth/steam` in the same session (login CSRF guard).

### GET /auth/failure

OmniAuth redirects here on failure. Redirects to `/?auth_error=<message>`, where `message` is the OmniAuth failure message (`unknown` if absent).

### POST /auth/register

Creates a new User, UserProfile, UserPreference, and Credential. Validates username (max 15 chars, alphanumeric + `-_`, must start and end with alphanumeric, reserved names `guest`/`api`/`admin`/`compilatron` and taken names are rejected; the name is lowercased before validation). Requires `session[:pending_auth]`.

**Request params:**

| Field | Notes |
|---|---|
| `name` | New username |
| `timezone` | IANA timezone identifier (optional; `UTC` if empty or invalid) |
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
| `422 Unprocessable Entity` | `{"error": "error-username-empty" \| "error-username-too-long" \| "error-username-invalid-chars" \| "error-username-reserved" \| "error-username-taken"}` | Invalid username |

### DELETE /auth/session

Clears `session[:user_id]`. Redirects to `/`.

### GET /api/v1/auth/current

Returns the current user and preferences. Used by the SPA on load to initialize `AuthContext`.

**Response `200 OK` (logged in):**

```json
{
  "user": {
    "name": "wube",
    "display_name": "Wube Software",
    "avatar_url": "https://cdn.example.com/wube/avatar/01HXY....jpg"
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
  "preferences": { "locale": null, "timezone": null, "relative_timestamps": false }
}
```

### GET /api/v1/auth/registration

Returns pending OAuth data for the registration form. Requires `session[:pending_auth]`.

**Response `200 OK`:**

```json
{ "provider": "github", "login_name": "wube" }
```

**Error responses:**

| Status | Condition |
|---|---|
| `401 Unauthorized` | No `session[:pending_auth]` |

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

`name` is required (max 30 grapheme clusters). It is the map's display name; if the map already exists, it replaces the stored name. `total_image_count` must be 1–10000, `metadata.map_id` and `metadata.unique_id` must be 8 lowercase hex characters, and `metadata.tick` an integer in 0..4294967295. If a pending upload already exists for the same generation, it is returned again with `201`.

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
| `400 Bad Request` | Invalid params |
| `403 Forbidden` | Guest |
| `409 Conflict` | A `complete` upload already exists for this generation |
| `422 Unprocessable Entity` | `{"error": "error-map-name-too-long" \| "error-map-name-invalid-chars"}` |
| `502 Bad Gateway` | S3 write of `mapshot.json` failed; DB records rolled back |

### POST /api/v1/uploads/:ulid/presigned_posts

Request presigned S3 POSTs for image files. They are generated locally, without an S3 API call. Each POST policy requires `Content-Type: image/jpeg` and a size of 1 byte to 640 KB. Send at most 200 filenames per call; each must match `s<surface>zoom_<zoom>/tile_<x>_<y>.jpg`.

**Request body:**

```json
{
  "filenames": ["s1zoom_4/tile_0_0.jpg", "s1zoom_4/tile_1_0.jpg", "..."]
}
```

**Response `200 OK`:**

```json
{
  "presigned_posts": {
    "s1zoom_4/tile_0_0.jpg": {
      "url": "https://bucket.s3.amazonaws.com/",
      "fields": { "key": "...", "policy": "...", "x-amz-signature": "..." }
    }
  }
}
```

The client submits each file as `multipart/form-data` to `url`, with `fields` first and the `file` part last.

**Error responses:**

| Status | Condition |
|---|---|
| `400 Bad Request` | Invalid or too many filenames |
| `403 Forbidden` | The map belongs to another user |
| `404 Not Found` | Upload with given ULID does not exist |
| `422 Unprocessable Entity` | Upload status is `complete` or `failed`, or the filenames would take the number of files requested for the upload above its `total_image_count` (asking again for a file already requested does not count) |

### POST /api/v1/uploads/:ulid/verify_batch

Check that the files of one batch exist in S3 (one `HeadObject` call per file) and record their sizes.

**Request body:** `{ "filenames": [...] }` (1–200 entries)

**Response `200 OK`:** `{ "verified_bytes": 123456 }` (the bytes of this batch, not a running total)

**Error responses:**

| Status | Condition |
|---|---|
| `403 Forbidden` | Guest user, or the map belongs to another user |
| `404 Not Found` | Upload with given ULID does not exist |
| `400 Bad Request` | `filenames` is empty or has more than 200 entries |
| `422 Unprocessable Entity` | Upload status is `complete` or `failed` (no body; nothing is checked), or an object is missing (`{ "error": "verification_failed" }`); the generation is deleted and its S3 prefix is queued for cleanup |
| `500 Internal Server Error` | The cleanup message could not be queued; the generation is kept |

### PATCH /api/v1/uploads/:ulid

Mark an upload as `complete`. This requires every expected file to be verified. Completing a complete upload answers `200` and changes nothing, so a client that lost the response can retry.

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
| `400 Bad Request` | `status` is not `complete` |
| `403 Forbidden` | Guest, or the map belongs to another user |
| `404 Not Found` | Upload with given ULID does not exist |
| `422 Unprocessable Entity` | Not all files have been verified, or the upload failed |

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
