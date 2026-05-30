# Project Structure

## Directory Layout

```
pasta_atlas/
  app/                   # Application code (Hanami)
    actions/             # HTTP actions (JSON API + HTML pages)
      auth/              # OAuth callbacks, registration, session
      maps/
      user/              # Profile view/edit, preferences, avatar, credential management
      uploads/
    views/               # Hanami views (HTML rendering)
    templates/           # ERB templates
    relations/           # ROM relations
    repos/               # Repositories
    structs/             # Immutable value objects (ROM structs)
    values/              # Non-ROM value objects
    middleware/          # Rack middleware
    operations/          # Use cases (orchestrate repos, S3, etc.)
  frontend/              # Vite source (island bundles only)
    components/          # Shared SolidJS components (not mounted as islands)
    islands/
      avatar_upload/     # AvatarUpload island
      map_info_button/   # MapInfoButton island
      map_viewer/        # LeafletMapViewer island
      share_buttons/     # ShareButtons island
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
| Island bundles | Vite + vite-plugin-solid | `public/assets/islands/` | Solid.js islands (LeafletMapViewer, UploadModal, AvatarUpload, MapInfoButton, ShareButtons) |

App templates load island bundles as `<script>` tags. Hanami serves both server-rendered pages and static assets from the same origin — no CORS configuration needed.
