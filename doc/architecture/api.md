# API Endpoints

The JSON API is specified in [openapi.yaml](../../openapi.yaml). This page covers the authentication endpoints that redirect instead of answering JSON. Authentication uses OmniAuth with GitHub, Discord and Steam.

### GET /auth/github/callback

OmniAuth GitHub OAuth callback. If a user is already logged in, the provider is linked to that account and the response redirects to `/@{name}#tab-credentials` (a `error-credential-conflict` flash is set when the credential belongs to another user or linking fails). Otherwise, for an existing credential the session is reset, `session[:user_id]` is set and the response redirects to `/`; for an unknown credential the OAuth data is stored in `session[:pending_auth]` and the response redirects to `/auth/register`. `400 Bad Request` if the OmniAuth data is missing.

### GET /auth/discord/callback

OmniAuth Discord OAuth callback. Same behavior as the GitHub callback.

### POST /auth/steam/callback

OmniAuth Steam OAuth callback. Same behavior as the GitHub callback, but rejected with `400 Bad Request` unless the login was started through `/auth/steam` in the same session (login CSRF guard).

### GET /auth/failure

OmniAuth redirects here on failure. Redirects to `/?auth_error=<message>`, where `message` is the OmniAuth failure message (`unknown` if absent).

### DELETE /auth/session

Clears `session[:user_id]`. Redirects to `/`.
