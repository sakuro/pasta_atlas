# Pasta Atlas

A web application for browsing Factorio map screenshots captured by the [mapshot](https://github.com/Palats/mapshot) mod.

## Getting started

Prerequisites: [mise](https://mise.jdx.dev/) (it installs Ruby and Node.js), Docker, and an OAuth app or API key for at least one of GitHub, Discord and Steam.

```sh
docker compose up -d                    # floci (S3, SQS and RDS)
(cd terraform/environments/local && terraform init && terraform apply)   # S3 bucket, SQS queue and RDS instance (takes about a minute)
# add OAuth credentials to .env.development.local
mise run setup                          # dependencies and database
pitchfork start --local                 # http://localhost:2300
```

The AWS profile, the OAuth settings and the details of each step are in [doc/development/local-setup.md](doc/development/local-setup.md).

## Testing

```sh
mise run check                   # RSpec, RuboCop, type check, ESLint and Vitest
```

## Documentation

See [`doc/`](doc/README.md) for the architecture, operations and development documents.
