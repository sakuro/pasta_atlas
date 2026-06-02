# Project Structure

## Directory Layout

```
pasta_atlas/
  app/                   # Application code (Hanami)
    actions/             # HTTP actions (SPA shell + JSON API)
      auth/              # OAuth callbacks, registration, session
      spa/               # SPA shell delivery
      api/               # JSON API
        auth/
        maps/
        uploads/
        users/
        pages/
    views/               # Hanami views (HTML rendering)
    templates/           # ERB templates
    relations/           # ROM relations
    repos/               # Repositories
    structs/             # Immutable value objects (ROM structs)
    values/              # Non-ROM value objects
    middleware/          # Rack middleware
    operations/          # Use cases (orchestrate repos, S3, etc.)
  frontend/              # Vite source (SPA)
    app.tsx              # Entry point (routing, providers)
    pages/               # Page components (MapsIndexPage, MapViewerPage, UserPage, …)
      map_viewer/        # MapViewer and Leaflet subcomponents
      user/              # UserPage tab components
    layout/
      AppLayout.tsx      # Shared navbar, upload button, footer
    components/          # Shared SolidJS components
    contexts/            # AuthContext, ToastContext
    lib/                 # l10n.ts, display-settings.ts
    factorio-icons/      # Factorio icon assets
  vite.config.ts
  tsconfig.json
  package.json           # single package.json for both hanami-assets and Vite
  public/                # Static files served by Hanami
  spec/                  # RSpec tests
  doc/
    design/              # Design documents
```

## Asset Pipeline

Two build pipelines run in parallel:

| Pipeline | Tool | Output | Handles |
|---|---|---|---|
| General assets | hanami-assets (esbuild) | `public/assets/` | Global CSS, fonts, images (files under `app/assets/`) |
| SPA bundle | Vite + vite-plugin-solid | `public/assets/` | Single SPA entry (`frontend/app.tsx`) |

Hanami serves both from the same origin — no CORS configuration needed. A custom `hanamiViteEntries` Vite plugin writes `vite-entries.json` after each build so hanami-assets can resolve the content-hashed filenames.
