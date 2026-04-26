# Project Structure

## Directory Layout

```
pasta_atlas/
  app/                   # Shared domain logic (Hanami)
    relations/           # ROM relations
    repos/               # Repositories
    operations/          # Use cases
    services/            # External service adapters (S3, CloudFront)
  slices/
    web/                 # Server-rendered HTML pages
      actions/
        maps/
      views/
        maps/
      templates/
        maps/
        layouts/
    api/                 # REST API for client-side islands
      actions/
        maps/
        uploads/
  frontend/              # Vite project (island bundles only)
    src/
      islands/
        map_viewer/      # LeafletMapViewer island
        upload_modal/    # UploadModal island
    package.json
    vite.config.ts
    tsconfig.json
  public/                # Static files served by Hanami
  infra/                 # Terraform
    modules/             # Reusable modules (s3, cloudfront, rds, etc.)
    environments/
      development/
      production/
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

The `web` slice templates load island bundles as `<script>` tags. Hanami serves both server-rendered pages and static assets from the same origin — no CORS configuration needed.
