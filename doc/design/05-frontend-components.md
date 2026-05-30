# Frontend Component Design

Framework: Solid.js (islands) + Bulma + Leaflet.js

Regular page navigation uses server-rendered HTML. Client-side JavaScript is used only for interactive islands.

## URL Structure

| Page | URL | Rendered by |
|---|---|---|
| Top page | `/` | `web` slice (server) |
| Map viewer | `/@:userProfileName/maps/:mapUlid` | `web` slice (shell) + Leaflet island |

Map viewer query parameters (managed by the Leaflet island via `history.replaceState`):

| Param | Description | Default |
|---|---|---|
| `generation` | Generation ULID | latest (first in API response, sorted by tick desc) |
| `s` | Surface index | first planet surface (`is_planet: true`) |
| `x`, `y`, `z` | Map center and zoom | surface center, zoom_min |
| `lt` | Train stations overlay visibility (`0`/`1`) | `1` |
| `lg` | Tags overlay visibility (`0`/`1`) | `1` |

`s`, `x`, `y`, `z`, `lt`, `lg` follow the same conventions as the mapshot standalone viewer.

## Server-Rendered Pages

### Top page (`/`)

Server-rendered. Fetches paginated map list from DB and renders MapCard list and Pagination. Full page reload on page change (`/maps?page=N`).

Shows only maps with at least one `complete` generation, ordered by most recent generation upload.

MapCard displays: `display_name`, owner name, latest generation tick, created_at. Links to `/@:userProfileName/maps/:ulid`.

`display_name` is resolved server-side: `name` → `savename` (if not empty) → `mapshot_map_id`.

### Map viewer page (`/@:userProfileName/maps/:mapUlid`)

Server-rendered as an HTML shell. The shell embeds the map ULID as a `data-` attribute on the island mount point. The Leaflet island mounts on this element and fetches map data from the API.

```erb
<div id="map-viewer" data-map-ulid="<%= map.ulid %>"></div>
```

## Client-Side Islands

### LeafletMapViewer island

Mounted on `#map-viewer`. Reads `data-map-ulid` on mount.

#### Data flow

```
1. Read data-map-ulid from mount element

2. Fetch GET /api/v1/maps/:mapUlid
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

#### GenerationSwitcher (internal, not a separate island)

Select input listing generations by tick value (descending). Rendered inside the Leaflet island.

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

### UploadModal island

Mounted on a fixed element in the application layout. Triggered by the upload button in the server-rendered NavBar.

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

### ShareButtons island

Mounted on the map viewer page. Renders share buttons for X, Bluesky, Reddit, and a copy-link button. Props: `mapPath` (URL path) and `mapName` (display name). The share URL is built from the current origin + `mapPath` + the active query string (preserving generation/surface/viewport state).
