# Secrets Management Plan

## Purpose

This document records the current proposal for handling production secrets in `pasta_atlas`.
It is intended as a decision aid before revisiting the Terraform module structure.

## Scope

The following values are treated as secrets:

| Value | Reason |
|---|---|
| PostgreSQL password / `DATABASE_URL` | Database access credential |
| `SESSION_SECRET` | Session signing secret |
| `GITHUB_CLIENT_SECRET` | OAuth client credential |
| `DISCORD_CLIENT_SECRET` | OAuth client credential |

The following values are configuration, but not secrets:

| Value | Reason |
|---|---|
| `GITHUB_CLIENT_ID` | Public OAuth application identifier |
| `DISCORD_CLIENT_ID` | Public OAuth application identifier |

## Current Repository State

The application already reads the relevant runtime values through Hanami settings:

- `SESSION_SECRET`
- `GITHUB_CLIENT_ID`
- `GITHUB_CLIENT_SECRET`
- `DISCORD_CLIENT_ID`
- `DISCORD_CLIENT_SECRET`

The current Terraform implementation is mixed:

- `SESSION_SECRET` is represented as an encrypted SSM Parameter Store value and injected into ECS tasks.
- `DATABASE_URL` is documented as a runtime secret, but the PostgreSQL password is currently expected through `terraform.tfvars`.
- OAuth client secrets are not yet modeled in Terraform-managed runtime secret injection.

The design documentation also needs to be normalized:

- `doc/design/10-infrastructure.md` describes Secrets Manager as the runtime secret store.
- `terraform/README.md` and the backend module currently use SSM Parameter Store for `SESSION_SECRET`.

## Recommended Direction

Use AWS-native secret management first. Vault remains an option only if the project later needs multi-cloud secret distribution, dynamic leased credentials across many systems, or a centralized secret platform beyond AWS.

### 1. PostgreSQL Credentials

Preferred direction:

- Avoid passing the database password into Terraform through `terraform.tfvars`.
- Prefer RDS-managed credentials stored in AWS Secrets Manager where feasible.
- Otherwise, store the database credential material in AWS Secrets Manager and inject the runtime value into the app from there.

Reasoning:

- Terraform state can retain secret values even when variables are marked sensitive.
- Database credentials have the strongest case for managed rotation.
- RDS and Secrets Manager are already aligned with the deployment platform.

Open design choice:

- Whether the app should receive a complete `DATABASE_URL` secret, or separate fields such as host, database, username, and password that are assembled during task startup.

### 2. Session Secret

Acceptable options:

- Keep `SESSION_SECRET` in SSM Parameter Store as `SecureString`.
- Move it to Secrets Manager for consistency with other runtime secrets.

Current pragmatic recommendation:

- Keeping `SESSION_SECRET` in SSM Parameter Store is acceptable if the project values lower operational overhead and the value is rotated manually and infrequently.
- Move it to Secrets Manager if the final design prefers one runtime secret backend for all application secrets.

Operational note:

- ECS environment-variable injection captures the secret value at task start. A secret update requires a new task or a forced service deployment before the app observes the new value.

### 3. OAuth Client Secrets

Recommended direction:

- Store `GITHUB_CLIENT_SECRET` and `DISCORD_CLIENT_SECRET` in AWS Secrets Manager.
- Inject them into ECS tasks as runtime secrets.
- Keep `GITHUB_CLIENT_ID` and `DISCORD_CLIENT_ID` as ordinary non-secret environment variables.

Reasoning:

- These are long-lived confidential client credentials.
- They should be replaceable without source-code or image changes.
- Secrets Manager aligns well with manual rotation procedures after provider-side regeneration.

## Terraform Boundary

Terraform should manage:

- Secret containers or parameter resources
- IAM policies that allow ECS tasks to read the required secret values
- ECS task definition references to those secret ARNs or parameter ARNs
- Supporting outputs that expose identifiers, not plaintext secret values

Terraform should avoid managing:

- Plaintext production secret values
- Secret material embedded directly in `.tfvars`
- Any approach that unnecessarily writes secret values into Terraform state

## Proposed Target Shape

| Runtime value | Suggested storage | ECS delivery |
|---|---|---|
| `DATABASE_URL` or DB credential material | Secrets Manager | ECS secret injection or startup retrieval |
| `SESSION_SECRET` | SSM SecureString or Secrets Manager | ECS secret injection |
| `GITHUB_CLIENT_SECRET` | Secrets Manager | ECS secret injection |
| `DISCORD_CLIENT_SECRET` | Secrets Manager | ECS secret injection |
| `GITHUB_CLIENT_ID` | Plain environment variable | ECS environment |
| `DISCORD_CLIENT_ID` | Plain environment variable | ECS environment |

## Migration Sketch

1. Decide whether runtime secrets should be split between SSM and Secrets Manager, or consolidated in Secrets Manager.
2. Remove the production database password from Terraform variable input if the module redesign permits it.
3. Add Terraform resources or data paths for OAuth client secrets.
4. Extend ECS task secret injection for GitHub and Discord client secrets.
5. Normalize `doc/design/10-infrastructure.md` and `terraform/README.md` so they describe the same implementation.
6. Document rotation procedures for:
   - database credentials
   - `SESSION_SECRET`
   - GitHub OAuth client secret
   - Discord OAuth client secret

## Questions To Resolve During Module Review

1. Should the backend module own runtime secret resources directly, or should secret resources live in a separate module?
2. Should `SESSION_SECRET` stay in SSM or move to Secrets Manager for consistency?
3. Should database secret generation be coupled to the RDS resource, or handled as an application secret independent of the RDS module?
4. Should ECS receive secrets only through task definition injection, or should the app retrieve some values programmatically at startup?
5. Which outputs should be exposed for operators without leaking secret values?

