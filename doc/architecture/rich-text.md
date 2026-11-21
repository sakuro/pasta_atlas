# Factorio Rich Text

Factorio allows train stop names (`backer_name`) and map tags (`text`) to contain rich text tags that embed item icons, colors, and other visual elements. This document describes how pasta_atlas renders them in HTML.

## Where It Appears

| Data | Field | Rendering context |
|---|---|---|
| Station marker | `Surface.stations[].backer_name` | Permanent Leaflet tooltip (`bindTooltip`) |
| Map tag marker | tag `text` | Permanent Leaflet tooltip (`bindTooltip`) |
| Layer switcher label | Localized surface name: FTL lookup by `surface_name`, falling back to `surface_localised_name` / `surface_name`; planets get a `[planet=<surface_name>]` prefix | Leaflet `control.layers` key |

All three are processed by `renderRichText()` in `frontend/pages/map_viewer/richtext/index.ts`.

## Tag Reference

### Icon tags (self-closing)

Produce an `<i>` element. The original value is preserved as text content (hidden via CSS) and `aria-hidden="true"` marks the icon as decorative.

```
[item=iron-ore]   →  <i class="factorio-icon factorio-item--iron-ore" aria-hidden="true">iron-ore</i>
[space-age]       →  <i class="factorio-icon factorio-space-age" aria-hidden="true"></i>
```

Supported tag names:

| Tag | Sprite directory | Notes |
|---|---|---|
| `item` | `item/` | Supports `,quality=tier` suffix |
| `entity` | `entity/` | Supports `,quality=tier` suffix |
| `fluid` | `fluid/` | Supports `,quality=tier` suffix |
| `recipe` | `recipe/` | Supports `,quality=tier` suffix |
| `virtual-signal` | `virtual-signal/` | Supports `,quality=tier` suffix |
| `technology` | `technology/` | |
| `item-group` | `item-group/` | |
| `achievement` | `achievement/` | |
| `tile` | `tile/` | |
| `quality` | `quality/` | |
| `space-location` | `space-location/` | |
| `planet` | `space-location/` | No `planet/` directory; reuses `space-location/` sprites |
| `shortcut` | `shortcut/` | |
| `img` | varies | Works for every directory under `frontend/factorio-icons/`. Value is `type/name`; slash becomes hyphen in class name (e.g. `[img=item/iron-ore]` → `factorio-img--item-iron-ore`). No alias needed; write the sprite directory name as-is (e.g. `[img=space-location/nauvis]`, not `[img=planet/nauvis]`) |
| `gps`, `train-stop`, `train`, `space-platform`, `special-item`, `armor`, `tip` | — | No sprites; `<i>` renders without background |
| `space-age` | — | No value; no sprite |

#### Quality modifier

`[item=iron-ore,quality=legendary]` wraps the item icon and a quality overlay icon in a single `<span>`. The quality icon is rendered at 50% size, anchored to the bottom-left corner of the item icon via `position: absolute`.

```
[item=iron-ore,quality=legendary]
  →  <span class="factorio-icon-with-quality">
       <i class="factorio-icon factorio-item--iron-ore" ...>iron-ore</i>
       <i class="factorio-icon factorio-quality--legendary factorio-quality-overlay" ...>legendary</i>
     </span>
```

### Wrapping tags

| Tag | HTML output | Notes |
|---|---|---|
| `[color=red]...[/color]` | `<span style="color:red">...</span>` | Named color |
| `[color=0.5,0,0]...[/color]` | `<span style="color:rgba(128,0,0,1)">...</span>` | RGB floats 0–1 |
| `[color=0.5,0,0,0.5]...[/color]` | `<span style="color:rgba(128,0,0,0.5)">...</span>` | RGBA; the alpha value is used as given |
| `[color=#ff0000]...[/color]` | `<span style="color:#ff0000">...</span>` | Hex `#rrggbb` |
| `[color=#80ff0000]...[/color]` | `<span style="color:rgba(255,0,0,0.502)">...</span>` | Factorio ARGB `#aarrggbb` |
| `[font=default-bold]...[/font]` | `<span class="factorio-font--default-bold">...</span>` | No font assets wired |
| `[tooltip=...]...[/tooltip]` | `<span>...</span>` | Tooltip data not surfaced |

An unparsable color value produces a `<span>` without a style. Unclosed tags are auto-closed at end of string. Unmatched closing tags are discarded.

### Unknown tags

Any tag not in the above sets is HTML-escaped and output as literal text:

```
[unknown=foo]  →  [unknown=foo]
```

## CSS Class Naming

```
factorio-{tagName}--{sanitizedValue}
```

`sanitizedValue` replaces any character outside `[a-zA-Z0-9-]` with `-`. Case is preserved (e.g. `signal-A` stays `signal-A`).

Special cases:
- `[space-age]` (no value): `factorio-space-age` (no `--`)
- `[img=item/iron-ore]`: slash → hyphen → `factorio-img--item-iron-ore`
- `[planet=nauvis]`: class is `factorio-planet--nauvis`, mapped to `space-location/nauvis.png`

## Icon Assets

Sprites are tracked in `frontend/factorio-icons/{type}/{name}.png` and processed by Vite at build time — no manual copy step is needed.

`richtext-icons.css` (imported by `richtext.css`) maps each sprite to its CSS class using relative paths:

```css
.factorio-item--iron-ore        { background-image: url('../../../factorio-icons/item/iron-ore.png'); }
.factorio-img--item-iron-ore    { background-image: url('../../../factorio-icons/item/iron-ore.png'); }
.factorio-planet--nauvis        { background-image: url('../../../factorio-icons/space-location/nauvis.png'); }
```

Vite rewrites these relative paths during bundling and emits the PNG files alongside the built CSS. `vite.config.ts` sets `assetsInlineLimit: 0` to prevent small sprites from being base64-inlined.

### Regenerating CSS

Run `scripts/generate-richtext-icons-css` after adding or removing sprites.
