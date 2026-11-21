# PastaAtlas

A web application for browsing Factorio map screenshots captured by the [mapshot](https://github.com/Palats/mapshot) mod. Users upload tile sets to S3; the app stores metadata in PostgreSQL and serves an interactive map viewer built with SolidJS and Leaflet.

The production site runs on AWS Lambda behind CloudFront.

## Tech stack

| Layer | Technology |
|-------|-----------|
| Backend | [Ruby](https://www.ruby-lang.org/) / [Hanami](https://hanakai.org/hanami), [ROM](https://hanakai.org/rom) |
| Frontend | [SolidJS](https://www.solidjs.com/) / [Vite](https://vitejs.dev/), [Leaflet](https://leafletjs.com/), [Bulma](https://bulma.io/) |
| Database | PostgreSQL |
| Storage and queue | AWS S3 and SQS (local: [floci](https://floci.io/)) |

## Getting started

Prerequisites: [mise](https://mise.jdx.dev/) (it installs Ruby and Node.js), Docker, and an OAuth app or API key for at least one of GitHub, Discord and Steam.

```sh
docker compose up -d                    # PostgreSQL and floci
(cd terraform/environments/local && terraform init && terraform apply)   # S3 bucket and SQS queue
# add OAuth credentials to .env.development.local
bin/setup                               # dependencies and database
bin/dev                                 # http://localhost:2300
```

The AWS profile, the OAuth settings and the details of each step are in [doc/development/local-setup.md](doc/development/local-setup.md).

## Testing

```sh
bundle exec rake                 # RSpec and RuboCop
npm run type-check
npm run lint:frontend
npm run test:frontend -- --run
```

## Documentation

See [`doc/`](doc/README.md) for the architecture, operations and development documents.
