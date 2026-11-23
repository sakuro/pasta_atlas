# Code Quality

## Backend (Ruby)

| Tool | Purpose |
|---|---|
| RuboCop | Static analysis and style enforcement |
| docquet | RuboCop configuration provider (inherits comprehensive style rules) |
| rubocop-capybara, rubocop-performance, rubocop-rake, rubocop-rspec, rubocop-sequel, rubocop-thread_safety | RuboCop plugins |
| RSpec | Unit and integration testing; factories use `rom-factory` |
| simplecov | Code coverage with branch coverage; the run fails below 80% line coverage (`.simplecov`) |
| gitleaks | Secret scanning (`.gitleaks.toml`) |
| json_schemer | Checks action responses against `openapi.yaml` (`conform_to_openapi` in `spec/support/openapi.rb`); `spec/open_api_document_spec.rb` checks that the document is valid and covers the JSON routes |

`mise run spec` and `mise run rubocop` run RSpec and RuboCop, and `mise run rubocop:autocorrect` applies the safe corrections. `mise run check` runs both together with the frontend checks.

## Frontend (TypeScript / Solid.js)

| Tool | Command | Purpose |
|---|---|---|
| TypeScript | `npm run type-check` | Static typing (`tsc --noEmit`) |
| ESLint + `eslint-plugin-solid` | `npm run lint:frontend` | Static analysis for `frontend/**/*.{ts,tsx}`, with the `v2` configuration |
| Vitest | `npm run test:frontend` | Unit tests (jsdom); add `-- --run` for a single run |
| Vite + `@solidjs/vite-plugin` | `npm run build:frontend` | Build; compiles Solid JSX |
| Prettier | `npm run format:frontend` | Formats `frontend/**/*.{ts,tsx}` in place (`.prettierrc`, 120 columns); the `pre-commit` hook checks it, CI does not |
| Hey API (`@hey-api/openapi-ts`) | `npm run generate:api` | Generates the typed client in `frontend/lib/api/gen/` from `openapi.yaml` (`openapi-ts.config.ts`); commit the result. ESLint skips the generated files |

## Git hooks

[hk](https://hk.jdx.dev/) runs the hooks configured in `hk.pkl`; `mise install` installs them (`hk install`). The steps come from hk's builtins and from [git-hooks](https://github.com/sakuro/git-hooks).

| Hook | Steps |
|---|---|
| `commit-msg` | `emoji-enforced`: the subject starts with a `:gitmoji:` |
| `prepare-commit-msg` | `merge-prefix`: prefixes merge commits with `:inbox_tray:` |
| `pre-commit` | `gitleaks` (staged changes), `no-commit-to-branch`, `rubocop`, `eslint` and `prettier` (`frontend/`), `terraform fmt`, `tflint` |
| `pre-push` | `case-conflict`, `newlines` |

The hooks check only; they do not rewrite files. RSpec and the type check are not hooks: run `mise run check` before committing.

## CI

`.github/workflows/ci.yml` runs three jobs. `backend` prepares PostgreSQL 18, compiles the assets, loads the test database structure and seeds, then runs RSpec and RuboCop with the commands of the `spec` and `rubocop` mise tasks (CI does not install mise). `frontend` checks that the generated API client is current, then runs the type check, the lint and the Vitest run. `actions-lock` verifies `.github/workflows/actions.lock` with `gh actions-lock --verify`, so regenerate the lockfile after editing a workflow or bumping an action.
