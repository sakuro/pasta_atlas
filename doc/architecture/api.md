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
