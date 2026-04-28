# Project Structure

## Directory Layout

```
pasta_atlas/
  app/                   # Application code (Hanami)
    actions/             # HTTP actions
      uploads/
    relations/           # ROM relations
    repos/               # Repositories
    operations/          # Use cases
    services/            # External service adapters (S3, CloudFront)
  frontend/              # Vite source (island bundles only)
    islands/
      map_viewer/        # LeafletMapViewer island
      upload_modal/      # UploadModal island
  vite.config.ts
  tsconfig.json
  package.json           # single package.json for both hanami-assets and Vite
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
