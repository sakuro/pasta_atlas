# Comments

## Overview

Map viewers and the map owner can attach comments to specific locations on the map. The primary use case is interaction between the map owner and other logged-in users.

- Logged-in users can post and reply.
- Guests can read but not post.
- The map owner can hide or delete any comment on their map.

## Location Model

A comment is anchored to a specific point identified by four values:

| Field | Type | Notes |
|---|---|---|
| `world_x` | integer | Factorio world coordinate |
| `world_y` | integer | Factorio world coordinate |
| `surface_index` | integer | Index into `surfaces[]` in mapshot.json |
| `zoom_level` | integer | Integer-snapped zoom at creation time |

**Why world coordinates:** Stable regardless of mapshot rendering parameters (`render_size`, `tile_size`). Meaningful to Factorio players (matches in-game coordinate display).

**Why `surface_index` instead of `surface_name`:** Multiple space platforms can share the same name, making `surface_name` non-unique within a generation. `surface_index` is unique within a generation. Index drift across generations is acceptable because comments are tied to a specific generation and markers always appear on that generation's map.

Surface display name is derived at render time from the already-loaded mapshot.json (`surfaces[surface_index].surface_localised_name`) and is not stored.

**Why integer-snapped zoom:** mapshot tile zoom levels are integers (`s1zoom_4/`, etc.). Snapping to the nearest integer at creation time maps cleanly to tile zoom levels.

## Comment Scope

Comments are scoped to a **generation**, not a map. A comment created on generation G1 belongs to G1 and is not transferred to G2.

## Marker Visibility

A comment marker is visible on the map only when all three conditions hold:

1. The active generation matches the comment's generation.
2. The active surface layer matches `surface_index`.
3. Current zoom ≥ `zoom_level` (fixed threshold; comment created at zoom 4 appears at zoom 4 and above).

## List View

The comment list shows only comments belonging to the active generation. Comments from other generations are not listed.

The generation switcher displays a comment count badge next to each generation, giving users a signal that comments exist in other generations.

## Threading

Replies are one level deep (flat threading). A top-level comment can have multiple replies; replies cannot have replies.

## Features

| Feature | Notes |
|---|---|
| Post comment | Logged-in users only |
| Reply | 1-level flat; logged-in users only |
| Edit | Own comment/reply only |
| Delete | Own comment/reply; map owner can delete any |
| Hide | Map owner can hide any comment (hidden comments are not shown to others) |
| List | Active generation only |
| Jump to location | From list entry → fly to (world_x, world_y) on the correct surface at zoom_level |
| Permalink | `?comment=:ulid` in URL |
| New comment notification | Map owner only; deferred |
| Guest access | Read-only (no post, no reply) |

## Out of Scope

- Read/unread tracking
- Cross-generation list
- Report to administrator (owner moderation is sufficient for this use case)
- Reactions
- Mentions
- Public visibility settings

## Location Selection UI

The primary interface for placing a comment on the map:

**Comment mode toggle (primary)**
A toolbar button switches the map into comment mode. The cursor changes to `crosshair`. A click places the comment anchor at that location. Clicking again or pressing Escape exits the mode.

**Shift+click (secondary)**
Shift+clicking on the map opens the comment form directly, without entering comment mode first. Keyboard-only, so not available on mobile.

Both methods record `(world_x, world_y, surface_index, zoom_level)` from the click event and current map state.

Leaflet implementation notes:
- `map.on('click', e => ...)` provides `e.latlng`; invert `worldToLatLng` to recover world coordinates.
- Guard against `boxZoom` drag being misinterpreted as a comment click (check `mousedown` → `mouseup` displacement).
- `L.DomUtil.addClass(map._container, 'comment-mode')` applies cursor change without touching Leaflet internals.
