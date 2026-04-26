# Frontend Styling

## CSS Framework

[Bulma](https://bulma.io/) via SCSS customization. Built by hanami-assets (esbuild).

## Color Theme

Nord palette. Nord defines 16 colors across four groups:

| Group | Colors | Light theme role | Dark theme role |
|---|---|---|---|
| Polar Night | nord0–nord3 | Text (dark on light) | Backgrounds |
| Snow Storm | nord4–nord6 | Backgrounds and surfaces | Text |
| Frost | nord7–nord10 | Primary and accent colors | Same |
| Aurora | nord11–nord15 | Semantic colors | Same |

## Bulma Variable Mapping

Frost and Aurora colors are shared across both themes. Polar Night and Snow Storm swap roles between light and dark.

| Bulma variable | Nord | Value |
|---|---|---|
| `$primary` | nord10 | `#5E81AC` |
| `$link` | nord9 | `#81A1C1` |
| `$info` | nord8 | `#88C0D0` |
| `$success` | nord14 | `#A3BE8C` |
| `$warning` | nord13 | `#EBCB8B` |
| `$danger` | nord11 | `#BF616A` |

### Light theme

| Bulma variable | Nord | Value |
|---|---|---|
| `$text` | nord0 | `#2E3440` |
| `$background` | nord6 | `#ECEFF4` |
| `$border` | nord4 | `#D8DEE9` |

### Dark theme

| Bulma variable | Nord | Value |
|---|---|---|
| `$text` | nord4 | `#D8DEE9` |
| `$background` | nord0 | `#2E3440` |
| `$border` | nord3 | `#4C566A` |

Dark mode is applied via `prefers-color-scheme: dark` (automatic) and `data-theme="dark"` (manual toggle).
