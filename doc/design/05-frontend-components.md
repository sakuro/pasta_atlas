# Frontend Component Design

Framework: SolidJS + Bulma + Leaflet.js + `@solidjs/router`

The frontend is a SPA bundled by Vite from `frontend/app.tsx`. All page navigation is handled client-side by `@solidjs/router`. Hanami serves a minimal HTML shell (`<div id="app"></div>`) for every SPA route; the SPA mounts, fetches data from the JSON API, and renders the page.

## URL Structure

| Page | URL | Component |
|---|---|---|
| Map listing | `/` | `MapsIndexPage` |
| Map viewer | `/maps/:ulid` | `MapViewerPage` |
| User profile | `/@:user_name` | `UserPage` |
| Registration | `/auth/register` | `RegistrationPage` |
| About / Privacy / Terms | `/about`, `/privacy`, `/terms` | `StaticPage` |
| 404 | `*` | `NotFoundPage` |

Map viewer query parameters (managed by Leaflet via `history.replaceState`):

| Param | Description | Default |
|---|---|---|
| `generation` | Generation ULID | latest (first in API response, sorted by tick desc) |
| `s` | Surface index | first planet surface (`is_planet: true`) |
| `x`, `y`, `z` | Map center and zoom | surface center, zoom_min |
| `lt` | Train stations overlay visibility (`0`/`1`) | `1` |
| `lg` | Tags overlay visibility (`0`/`1`) | `1` |

`s`, `x`, `y`, `z`, `lt`, `lg` follow the same conventions as the mapshot standalone viewer.

## Application Shell

`AppLayout` wraps all pages. It renders the navbar, upload button, and footer. Auth state is held in `AuthContext`; `AppLayout` waits for the initial `GET /api/v1/auth/current` response before rendering page content, showing a spinner in the meantime.

## Pages

### MapsIndexPage (`/`)

Fetches `GET /api/v1/maps?page=N` and renders a paginated `MapCard` list. Page navigation is client-side (updates `?page=` search param without a full reload).

Shows only maps with at least one `complete` generation, ordered by most recent generation upload.

`MapCard` displays: `display_name`, owner name, latest generation tick, `created_at`. Links to `/maps/:ulid`.

### MapViewerPage (`/maps/:ulid`)

Fetches `GET /api/v1/maps/:ulid`, then mounts the `MapViewer` component with Leaflet.

### UserPage (`/@:user_name`)

Fetches `GET /api/v1/users/:name` and renders a tabbed profile page. The active tab is tracked via the URL hash.

Tabs:

| Tab | Visible to | Content |
|---|---|---|
| Maps | All | Recent maps by this user |
| Profile | Own profile only | Edit display name and avatar |
| Preferences | Own profile only | Timezone, locale, relative timestamps |
| Credentials | Own profile only | Linked OAuth providers |
| Danger | Own profile only | Account deletion |

### RegistrationPage (`/auth/register`)

Fetches `GET /api/v1/auth/registration` to get pending OAuth data (provider and suggested login name). Renders the username selection form. Submits `POST /auth/register`; on success the server returns `{"redirect_to": "/"}` and the SPA navigates there.

### StaticPage (`/about`, `/privacy`, `/terms`)

Fetches `GET /api/v1/pages/:slug` and renders the returned HTML content.

## Contexts

### AuthContext

Fetches `GET /api/v1/auth/current` on mount. Exposes `currentUser()` signal:
- `undefined` while loading
- `null` if not logged in (guest)
- user object `{ name, display_name, avatar_url }` if logged in

Also applies locale and timezone preferences from the response.

### ToastContext

Provides `showToast(message, type)` for transient notifications.

## Components

### MapViewer

Mounted inside `MapViewerPage`. Contains the Leaflet map.

#### Data flow

```
1. Receive map ULID from MapViewerPage

2. Fetch GET /api/v1/maps/:ulid
     → generations list (ulid, tick, metadata_url)

3. Resolve active generation from ?generation= or default to latest

4. Fetch mapshot.json from CloudFront (metadata_url)
     → surfaces[], stations[], tags[] per surface

5. Build SurfaceLayer objects (one per surface)
     → each holds baseLayer (tiles) + trainLayer (markers) + tagsLayer

6. Initialize Leaflet map; add active surface layers

7. generation change → update ?generation= → re-fetch mapshot.json → rebuild SurfaceLayers
   surface change    → Leaflet baselayerchange event → update ?s=
   pan/zoom          → update ?x= ?y= ?z=
   overlay toggle    → update ?lt= / ?lg=
```

#### GenerationSwitcher (internal, not a separate component)

Select input listing generations by tick value (descending). Rendered inside `MapViewer`.

On change: updates `?generation=` in URL → triggers mapshot.json re-fetch → rebuilds SurfaceLayers.

#### Leaflet configuration

```javascript
L.map("map-viewer", {
  crs: L.CRS.Simple,
  zoomSnap: 0.1,
  zoomDelta: 1.0,
  zoomsliderControl: true,
  zoomControl: false,
})
```

Additional controls:
- `L.Control.boxzoom` (top-left)
- `L.control.layers()` (top-right) — base layers (surfaces) + overlays (train stations, tags)

Surface switching and overlay toggles are handled by Leaflet's built-in layer control, consistent with the mapshot standalone viewer.

#### SurfaceLayer (internal class)

```javascript
class SurfaceLayer {
  baseLayer   // L.tileLayer.fallback(...)
  trainLayer  // L.layerGroup of station markers
  tagsLayer   // L.layerGroup of tag markers
}
```

Tile URL pattern:
```
{encoded_path}{surface.file_prefix}{z}/tile_{x}_{y}.jpg
```

`encoded_path` is derived from `metadata_url` by stripping the `mapshot.json` filename:
```
encodedPath = metadata_url.replace(/mapshot\.json$/, "")
```

Uses `leaflet.tilelayer.fallback` for graceful handling of missing tiles.

Coordinate conversion:
```javascript
worldToLatLng(x, y) {
  const ratio = surface.render_size / surface.tile_size
  return L.latLng(-y * ratio, x * ratio)
}
```

Station markers: `backer_name` is parsed via `renderRichText()` (`richtext.ts`) before being passed to Leaflet's `bindPopup`. Icon tags become `<i>` elements with CSS class names; wrapping tags become `<span>` elements. Unknown tags are escaped and output as literal text.

URL sync (via `history.replaceState`):
- `baselayerchange` → update `?s=`
- `zoomend` / `moveend` → update `?x=` `?y=` `?z=`
- `overlayadd` / `overlayremove` → update `?lt=` / `?lg=`

---

### UploadModal

Rendered in `AppLayout`. Triggered by the upload button in the navbar.

#### States

```
idle → instructions → confirming → uploading → done | error
```

| State | Description |
|---|---|
| `idle` | Modal closed |
| `instructions` | Upload instructions shown; user selects a directory |
| `confirming` | `mapshot.json` found; user confirms before starting |
| `uploading` | Uploading in progress |
| `done` | Complete; link to the newly uploaded generation |
| `error` | Upload failed |

Directory selection uses `<input type="file" webkitdirectory>`. The hidden input is triggered programmatically when the user clicks the select button in the `instructions` state.

#### Error patterns

| Trigger | State transition | User-visible outcome |
|---|---|---|
| Directory has no `mapshot.json` | `instructions → error` | Error message shown |
| `mapshot.json` parse failure (invalid JSON / unexpected structure) | `instructions → error` | Error message shown |
| User cancels directory picker | stays in `instructions` | Modal remains open |
| POST /api/v1/uploads → 409 Conflict | `uploading → error` | Message: already uploaded; link to existing generation |
| POST /api/v1/uploads → network / 5xx error | `uploading → error` | Generic error message |
| POST presigned_urls → network / 4xx / 5xx | `uploading → error` | Generic error message |
| S3 PUT fails (individual file) | `uploading → error` | Generic error message |
| PATCH /api/v1/uploads/:ulid → network error | `uploading → error` | Generic error message (images are uploaded; user can retry PATCH manually if needed) |

From the `error` state, the user can dismiss the modal (returning to `idle`) or go back to `instructions` to retry.

---

### ShareButtons

Used inside `MapViewerPage`. Renders share buttons for X, Bluesky, Reddit, and a copy-link button. Props: `mapPath` (URL path) and `mapName` (display name). The share URL is built from the current origin + `mapPath` + the active query string (preserving generation/surface/viewport state).
