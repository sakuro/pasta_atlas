# Code Quality

## Backend (Ruby)

| Tool | Purpose |
|---|---|
| RuboCop | Static analysis and style enforcement |
| docquet | RuboCop configuration provider (inherits comprehensive style rules) |
| rubocop-capybara, rubocop-performance, rubocop-rake, rubocop-rspec, rubocop-sequel, rubocop-thread_safety | RuboCop plugins |
| RSpec | Unit and integration testing; factories use `rom-factory` |
| simplecov | Code coverage with branch coverage; the run fails below 80% line coverage (`.simplecov`) |
| YARD + redcarpet | API documentation (`rake doc`, output in `doc/api/`) |
| gitleaks | Secret scanning (`.gitleaks.toml`) |

`rake` runs `spec` and then `rubocop`. `rake rubocop:autocorrect` applies the safe corrections.

## Frontend (TypeScript / Solid.js)

| Tool | Command | Purpose |
|---|---|---|
| TypeScript | `npm run type-check` | Static typing (`tsc --noEmit`) |
| ESLint + `eslint-plugin-solid` | `npm run lint:frontend` | Static analysis for `frontend/**/*.{ts,tsx}`, with the `v2` configuration |
| Vitest | `npm run test:frontend` | Unit tests (jsdom); add `-- --run` for a single run |
| Vite + `@solidjs/vite-plugin` | `npm run build:frontend` | Build; compiles Solid JSX |
| Prettier | — | Configured in `.prettierrc`; run manually, not part of CI |

## Git hooks

[hk](https://hk.jdx.dev/) runs the hooks configured in `hk.pkl`; `mise install` installs them (`hk install`). The steps come from hk's builtins and from [git-hooks](https://github.com/sakuro/git-hooks).

| Hook | Steps |
|---|---|
| `commit-msg` | `emoji-enforced`: the subject starts with a `:gitmoji:` |
| `prepare-commit-msg` | `merge-prefix`: prefixes merge commits with `:inbox_tray:` |
| `pre-commit` | `gitleaks` (staged changes), `no-commit-to-branch`, `rubocop`, `eslint` (`frontend/`), `terraform fmt`, `tflint` |
| `pre-push` | `case-conflict`, `newlines` |

The hooks check only; they do not rewrite files. RSpec and the type check are not hooks: run `rake` and `npm run type-check` before committing.

## CI

`.github/workflows/ci.yml` runs three jobs. `backend` prepares PostgreSQL 18, compiles the assets, loads the test database structure and seeds, then runs `bundle exec rake`. `frontend` runs the type check, the lint and the Vitest run. `actions-lock` verifies `.github/workflows/actions.lock` with `gh actions-lock --verify`, so regenerate the lockfile after editing a workflow or bumping an action.
