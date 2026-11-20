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

## CI

`.github/workflows/ci.yml` runs two jobs. `backend` prepares PostgreSQL 18, compiles the assets, loads the test database structure and seeds, then runs `bundle exec rake`. `frontend` runs the type check, the lint and the Vitest run.
