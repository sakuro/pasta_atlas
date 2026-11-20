# Documentation

| Directory | Contents |
|---|---|
| [`architecture/`](architecture/) | What the application is and how it works: [overview](architecture/overview.md), [application structure](architecture/application.md), [domain model](architecture/domain-model.md), [DB schema](architecture/db-schema.md), [API](architecture/api.md), [frontend](architecture/frontend.md), [upload flow](architecture/upload-flow.md), [rich text](architecture/rich-text.md) |
| [`operations/`](operations/) | How it runs in production: [infrastructure](operations/infrastructure.md), [Lambda](operations/lambda.md), [secrets](operations/secrets.md). Terraform usage is in [`terraform/README.md`](../terraform/README.md) |
| [`development/`](development/) | Working on it: [local setup](development/local-setup.md), [code quality](development/code-quality.md) |

## Guidelines

- Describe the current state. History belongs in git and in issues and pull requests.
- State each fact in one place and link to it from elsewhere.
- Update the documents in the same pull request as the code change.
