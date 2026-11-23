# Frontend

Stack: SolidJS 2 (`solid-js`, `@solidjs/web`), `@solidjs/router` 2, Bulma, Leaflet, Fluent (localization) and FontAwesome.

The frontend is a SPA bundled by Vite from `frontend/app.tsx`. Hanami serves a minimal HTML shell (`<div id="app"></div>`) for the SPA routes; the SPA mounts, fetches data from the JSON API, and renders the page. Navigation is handled client-side. For the layout of `frontend/` see [application.md](application.md).

## Routes

Defined with `createRouter` in `frontend/app.tsx`:

| URL | Component |
|---|---|
| `/` | `MapsIndexPage` |
| `/maps/:ulid` | `MapViewerPage` |
| `/@:user_name` | `UserPage` (route `/:at_user_name`, filtered to values starting with `@`) |
| `/auth/register` | `RegistrationPage` |
| `/about`, `/privacy`, `/terms` | `StaticPage` |
| `*` | `NotFoundPage` |

The server renders the shell with status 404 for unknown maps, users and paths, and 403 for non-public profiles; the SPA shows the matching state.

Map viewer query parameters (kept in the URL with `history.replaceState`; see `pages/map_viewer/url_params.ts`):

| Param | Description | Default |
|---|---|---|
| `generation` | Generation ULID | newest generation (first in the API response); an unknown ULID falls back to it |
| `s` | Index into `surfaces[]` | first planet surface (`is_planet`), else the first surface |
| `x`, `y`, `z` | Map center (world coordinates) and zoom | the map fits the surface bounds |
| `lt` | Train stations overlay (`0`/`1`) | `0` (hidden) |
| `lg` | Tags overlay (`0`/`1`) | `0` (hidden) |

Changing the generation removes `s`, `x`, `y` and `z`.

## Application shell

`AppLayout` wraps all routes. It renders the fixed navbar (upload buttons, disabled for guests; `NavAuthMenu`), the route content, and the fixed footer. Content is replaced by a spinner until the initial `GET /api/v1/auth/current` response has arrived.

## Pages

| Page | Behavior |
|---|---|
| `MapsIndexPage` | `GET /api/v1/maps?page=N` (20 per page); client-side pagination through `?page=`. `MapCard` shows the thumbnail, `display_name`, the author (linked to the user page except for the guest), `updated_at`, and info and share buttons. |
| `MapViewerPage` | `GET /api/v1/maps/:ulid`; 404 shows `error-map-not-found`. Passes the map data to `MapViewer`. |
| `UserPage` | `GET /api/v1/users/:user_name` (404 and 403 have their own messages). The active tab is kept in the URL hash (`#tab-recent-maps`, `#tab-profile`, `#tab-preferences`, `#tab-credentials`, `#tab-danger`). Maps is visible to all; the others only on the own profile. |
| `RegistrationPage` | `GET /api/v1/auth/registration` returns the pending OAuth data (401 redirects to `/`). Submits `POST /auth/register` with the name, the browser timezone and the terms agreement. On success it reloads the app at `/` (`window.location.assign`), because the session changed and the CSRF token in the page is stale. |
| `StaticPage` | `GET /api/v1/pages/:slug`; refetched when the display language changes, because the server picks the locale. |

## Contexts

- `AuthContext` provides `currentUser()` (`undefined` while loading, `null` for guests, otherwise `{ name, display_name, avatar_url }`), `refetch()` and `updateCurrentUser(patch)`. A failed request is treated as a guest. The response's locale, timezone and relative-timestamp preferences are applied through `lib/display-settings.ts`.
- `ToastContext` provides `showToast(l10nId, type?)`; `type` is `success` (default), `danger`, `warning` or `info`. Toasts disappear after 5 seconds.

## Map viewer

`MapViewer` receives the map data from `MapViewerPage` and fetches `GET /api/v1/maps/:ulid` itself for the generation list.

```
1. Generations (ulid, tick, metadata_url), newest first
2. Active generation = ?generation= or the first one
3. Fetch mapshot.json (metadata_url) → surfaces[] with stations and tags
4. LeafletMap builds a tile layer and the station and tag markers per surface
5. The map starts on the surface from ?s=

generation change → set ?generation=, drop s/x/y/z, re-mount LeafletMap
surface change    → baselayerchange → update ?s=, repopulate the overlays
pan / zoom        → update ?x= ?y= ?z=
overlay toggle    → update ?lt= / ?lg=
```

The toolbar has `MapNameEditor` (owner only; `PATCH /api/v1/maps/:ulid/name`), `GenerationSelect` (labels use `formatTicks`), `MapInfoModal`, `ShareButtons`, and, for the owner, a delete button with a confirmation (`POST /api/v1/maps/:ulid/deletion_requests`).

### Leaflet

- `L.map` with `crs: L.CRS.Simple`, `zoomSnap: 0.1`, `zoomDelta: 1.0` and the default zoom control disabled. Zoom limits come from the active surface.
- Custom controls under `pages/map_viewer/leaflet/`: `ZoomSliderControl`, `BoxZoomControl` and `LayerControl`. `LayerControl` lists the surfaces (planets, space platforms, others) and two overlay toggles (train stations, tags). It fires `baselayerchange`, `overlayadd` and `overlayremove` itself.
- Tiles use a plain `L.tileLayer` with `minNativeZoom` and `maxNativeZoom` from the surface, so other zoom levels are scaled. The URL is `{assetBase}{file_prefix}{z}/tile_{x}_{y}.jpg`, where `assetBase` is `metadata_url` without `mapshot.json`.
- World to map coordinates: `L.latLng(-y * ratio, x * ratio)` with `ratio = render_size / tile_size`.
- Station and tag markers are FontAwesome `divIcon`s with permanent tooltips. Their text goes through `renderRichText()`; see [rich-text.md](rich-text.md).

## Upload modal

`UploadModal` is rendered through a `Portal`; `HowToUploadModal` explains the procedure. States:

```
idle → instructions → confirming → (per batch: preparing → uploading → verifying) → done | error
```

| State | Description |
|---|---|
| `instructions` | The user selects a directory (`<input type="file" webkitdirectory>`, triggered from the select button) |
| `confirming` | `mapshot.json` found; shows surfaces, image count and size; the map name is editable (max 30 grapheme clusters) and prefilled from `GET /api/v1/maps/lookup` |
| `preparing` | Requesting presigned POSTs for a batch |
| `uploading` | Posting the files to S3 |
| `verifying` | `verify_batch` for the batch |
| `done` | Link to the new generation |

The request sequence is described in [upload-flow.md](upload-flow.md).

| Trigger | Outcome |
|---|---|
| No `mapshot.json`, invalid JSON, a `mapshot.json` without string `map_id`/`unique_id` or an integer `tick`, or more than 10,000 `.jpg` files | `instructions → error` |
| User cancels the directory picker | Stays in `instructions` |
| `POST /uploads` fails (409 conflict, 422 with the server's error key, other statuses, network) | `error` with a matching message |
| `presigned_posts`, S3 POST, `verify_batch` or the final `PATCH` fails | `error` with a generic message |

From `error` the user can reselect a folder or dismiss the modal (`idle`). An upload that failed after Step 1 is resumed by selecting the same folder again.

## Shared pieces

| Piece | Role |
|---|---|
| `ShareButtons` | X, Bluesky, Reddit and copy-link buttons; used in `MapViewer` and `MapCard`. The URL comes from `lib/share-url.ts` (`buildShareUrl`): the generation of `mapPath` wins and the other parameters come from the current location. |
| `FormattedDateTime` | Absolute or relative time according to the user's preference |
| `lib/l10n.ts` | Fluent localization; elements carry `data-l10n-id` |
| `lib/display-settings.ts` | Signals for the language, timezone and relative timestamps |
| `lib/api/client.ts` | Typed functions for the JSON API (`listMaps`, `showMap`, …), generated by Hey API from [openapi.yaml](../../openapi.yaml) into `lib/api/gen/` (`npm run generate:api`). The client sends the CSRF token of the page's `csrf-token` meta tag; `errorKey` reads the l10n key of an `{"error": …}` body. |

## Solid 2 conventions

- Pages load data with `createMemo(async …)` inside `<Errored>` and `<Loading>`; `isPending` keeps the old content visible while the next page loads.
- State that is fetched but also patched locally uses a writable async signal (`createSignal(async () => …)`), as in `AuthContext`.
- `createEffect` takes separate compute and apply functions. `onSettled` handles mount-time work and cleanup (Leaflet, redirects).
- Context providers render as `<AuthContext value={…}>`; `render` comes from `@solidjs/web`.

## Styling

Bulma 1.x (plain CSS import, default palette) and FontAwesome Free are imported by both bundles. Project CSS is in `app/assets/css/app.css`: the fixed navbar and footer with z-indexes above the Leaflet controls, the viewer-page layout that locks page scrolling so `#map-viewer` fills the viewport, and the footer branding.

Dark mode follows `prefers-color-scheme` through Bulma's `--bulma-scheme-brightness: dark`; there is no manual toggle. Leaflet controls are themed with `--leaflet-ctrl-*` custom properties defined in `app.css` and used by `pages/map_viewer/leaflet/*.css`. Rich text icons and fonts are in `pages/map_viewer/richtext/`.
