# Project Structure

## Directory Layout

```
pasta_atlas/
  app/                   # Application code (Hanami)
    actions/             # HTTP actions (JSON API + HTML pages)
      auth/              # OAuth callbacks, registration, session
      maps/
      profile/           # Profile view/edit and avatar management
      uploads/
    views/               # Hanami views (HTML rendering)
    templates/           # ERB templates
    relations/           # ROM relations
    repos/               # Repositories
    structs/             # Immutable value objects (ROM structs)
    operations/          # Use cases (orchestrate repos, S3, etc.)
  frontend/              # Vite source (island bundles only)
    islands/
      avatar_upload/     # AvatarUpload island
      map_viewer/        # LeafletMapViewer island
      upload_modal/      # UploadModal island
  vite.config.ts
  tsconfig.json
  package.json           # single package.json for both hanami-assets and Vite
  public/                # Static files served by Hanami
  spec/                  # RSpec tests
  doc/
    design/              # Design documents
    api/                 # YARD-generated API documentation
```

## Asset Pipeline

Two build pipelines are used with distinct responsibilities:

| Pipeline | Tool | Output | Handles |
|---|---|---|---|
| General assets | hanami-assets (esbuild) | `public/assets/` | Global CSS (Bulma), fonts, images |
| Island bundles | Vite + vite-plugin-solid | `public/islands/` | Solid.js islands (LeafletMapViewer, UploadModal) |

App templates load island bundles as `<script>` tags. Hanami serves both server-rendered pages and static assets from the same origin — no CORS configuration needed.
