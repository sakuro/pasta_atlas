# Code Quality

## Backend (Ruby)

| Tool | Purpose |
|---|---|
| RuboCop | Static analysis and style enforcement |
| docquet | RuboCop configuration provider (inherits comprehensive style rules) |
| rubocop-performance | RuboCop plugin: performance-related rules |
| rubocop-rspec | RuboCop plugin: RSpec-specific rules |
| rubocop-rake | RuboCop plugin: Rake file conventions |
| RSpec | Unit and integration testing |
| simplecov | Code coverage reporting integrated with RSpec |
| YARD + redcarpet | API documentation generation (`doc/api/` output) |
| ruby-lsp | Language server for editor integration |
| repl_type_completor | Type-aware completion in IRB/Pry |

`rubocop-capybara` and `rubocop-factory_bot` are added when those libraries are adopted.

### Rake

Hanami generates a Rakefile with a default task that runs the test suite (`rake` with no arguments runs RSpec). No override needed.

## Frontend (TypeScript / Solid.js)

| Tool | Purpose |
|---|---|
| TypeScript | Static typing |
| Vite + vite-plugin-solid | Build toolchain; uses Babel for Solid.js JSX transform |
| ESLint + `eslint-plugin-solid` | Static analysis including Solid.js-specific rules |
| Prettier | Code formatting |
| Vitest | Unit and component testing (shares Vite config) |
| `@solidjs/testing-library` | Component testing utilities for Solid.js |
| Playwright | End-to-end testing (added when needed) |
