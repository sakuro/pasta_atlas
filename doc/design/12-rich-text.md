# Factorio Rich Text

Factorio allows train stop names (`backer_name`) and map tags (`text`) to contain rich text tags that embed item icons, colors, and other visual elements. This document describes how pasta_atlas renders them in HTML.

## Where It Appears

| Data | Field | Rendering context |
|---|---|---|
| Station marker popup | `Surface.stations[].backer_name` | Leaflet `bindPopup` |
| Layer switcher label | `Surface.surface_localised_name` / `surface_name` | Leaflet `control.layers` key |

Both are processed by `renderRichText()` in `frontend/islands/map_viewer/richtext.ts`.

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
| `img` | varies | `[img=item/iron-ore]` → `space-location/` maps as-is |
| `gps`, `train-stop`, `train`, `space-platform`, `special-item`, `armor`, `tip` | — | No sprites; `<i>` renders without background |
| `space-age` | — | No value; no sprite |

#### Quality modifier

`[item=iron-ore,quality=legendary]` emits two consecutive icons: one for the item and one for the quality tier.

```
[item=iron-ore,quality=legendary]
  →  <i class="factorio-icon factorio-item--iron-ore" ...>iron-ore</i>
     <i class="factorio-icon factorio-quality--legendary" ...>legendary</i>
```

### Wrapping tags

| Tag | HTML output | Notes |
|---|---|---|
| `[color=red]...[/color]` | `<span style="color:red">...</span>` | Named color |
| `[color=0.5,0,0]...[/color]` | `<span style="color:rgba(128,0,0,1)">...</span>` | RGB floats 0–1 |
| `[color=#ff0000]...[/color]` | `<span style="color:#ff0000">...</span>` | Hex `#rrggbb` |
| `[color=#80ff0000]...[/color]` | `<span style="color:rgba(255,0,0,0.502)">...</span>` | Factorio ARGB `#aarrggbb` |
| `[font=default-bold]...[/font]` | `<span class="factorio-font--default-bold">...</span>` | No font assets wired |
| `[tooltip=...]...[/tooltip]` | `<span>...</span>` | Tooltip data not surfaced |

Unclosed tags are auto-closed at end of string. Unmatched closing tags are discarded.

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

Sprites are tracked in `app/assets/images/factorio-icons/{type}/{name}.png` and processed by Vite at build time — no manual copy step is needed.

`richtext-icons.css` (imported by `richtext.css`) maps each sprite to its CSS class using relative paths:

```css
.factorio-item--iron-ore        { background-image: url('../../../app/assets/images/factorio-icons/item/iron-ore.png'); }
.factorio-img--item-iron-ore    { background-image: url('../../../app/assets/images/factorio-icons/item/iron-ore.png'); }
.factorio-planet--nauvis        { background-image: url('../../../app/assets/images/factorio-icons/space-location/nauvis.png'); }
```

Vite rewrites these relative paths during bundling and emits the PNG files alongside the built CSS. `vite.config.ts` sets `assetsInlineLimit: 0` to prevent small sprites from being base64-inlined.

### Regenerating CSS

Run from the project root after adding or removing sprites:

```bash
{
  echo "/* Auto-generated from app/assets/images/factorio-icons — do not edit manually */"
  for dir in app/assets/images/factorio-icons/*/; do
    type="${dir%/}"; type="${type##*/}"
    for file in "$dir"*.png; do
      [ -f "$file" ] || continue
      name="${file%.png}"; name="${name##*/}"
      echo ".factorio-${type}--${name}{background-image:url('../../../app/assets/images/factorio-icons/${type}/${name}.png')}"
      echo ".factorio-img--${type}-${name}{background-image:url('../../../app/assets/images/factorio-icons/${type}/${name}.png')}"
      if [ "$type" = "space-location" ]; then
        echo ".factorio-planet--${name}{background-image:url('../../../app/assets/images/factorio-icons/space-location/${name}.png')}"
        echo ".factorio-img--planet-${name}{background-image:url('../../../app/assets/images/factorio-icons/space-location/${name}.png')}"
      fi
    done
  done
} > frontend/islands/map_viewer/richtext-icons.css
```

## Implementation Files

| File | Role |
|---|---|
| `frontend/islands/map_viewer/richtext.ts` | Parser: `renderRichText(input: string): string` |
| `frontend/islands/map_viewer/richtext.test.ts` | Vitest unit tests |
| `frontend/islands/map_viewer/richtext.css` | Base `.factorio-icon` styles; imports `richtext-icons.css` |
| `frontend/islands/map_viewer/richtext-icons.css` | Generated `background-image` mappings (do not edit manually) |
| `app/assets/images/factorio-icons/` | Sprite PNG source files (git-tracked; Vite processes at build time) |
