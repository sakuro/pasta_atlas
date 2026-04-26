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
  frontend/              # Vite project (island bundles)
    src/
      islands/
        map_viewer/      # LeafletMapViewer island
        upload_modal/    # UploadModal island
    package.json
    vite.config.ts
    tsconfig.json
  public/                # Vite build output; served by Hanami as static files
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

## Frontend Deployment

Vite builds island bundles into `public/`. The `web` slice templates load the bundles as `<script>` tags. Hanami serves both the server-rendered pages and the static assets from the same origin — no CORS configuration needed.
