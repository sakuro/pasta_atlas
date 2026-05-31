const ICON_TAGS = new Set([
  "item", "entity", "fluid", "technology", "recipe", "item-group",
  "virtual-signal", "achievement", "tile", "quality", "planet", "space-location",
  "img", "gps", "train-stop", "train", "space-platform",
  "special-item", "armor", "shortcut", "tip", "space-age",
]);

const WRAPPING_TAGS = new Set(["color", "font", "tooltip"]);

// Tags that support the [item=name,quality=tier] suffix syntax
const QUALITY_AWARE_TAGS = new Set(["item", "entity", "recipe", "fluid", "virtual-signal"]);

const ESCAPE_MAP: Record<string, string> = {
  "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
};

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ESCAPE_MAP[c]);
}

function sanitizeCssValue(s: string): string {
  return s.replace(/[^a-zA-Z0-9-]/g, "-");
}

function parseColor(value: string): string | null {
  if (/^[a-z]+$/i.test(value)) return value;

  if (value.startsWith("#")) {
    const hex = value.slice(1);
    if (hex.length === 6) return value;
    if (hex.length === 8) {
      // Factorio uses #aarrggbb (ARGB order)
      const aa = parseInt(hex.slice(0, 2), 16);
      const rr = parseInt(hex.slice(2, 4), 16);
      const gg = parseInt(hex.slice(4, 6), 16);
      const bb = parseInt(hex.slice(6, 8), 16);
      if ([aa, rr, gg, bb].some(isNaN)) return null;
      return `rgba(${rr},${gg},${bb},${(aa / 255).toFixed(3)})`;
    }
    return null;
  }

  const parts = value.split(",").map(Number);
  if (parts.some(isNaN)) return null;
  if (parts.length === 3 || parts.length === 4) {
    const [r, g, b, a = 1] = parts;
    const r255 = Math.max(0, Math.min(255, Math.round(r * 255)));
    const g255 = Math.max(0, Math.min(255, Math.round(g * 255)));
    const b255 = Math.max(0, Math.min(255, Math.round(b * 255)));
    return `rgba(${r255},${g255},${b255},${a})`;
  }

  return null;
}

// value=undefined means the tag had no '=' (e.g. [space-age]); value="" means explicit empty (e.g. [item=])
function renderIconElement(tagName: string, value: string | undefined): string {
  if (value === undefined) {
    return `<i class="factorio-icon factorio-${tagName}" aria-hidden="true"></i>`;
  }
  const cls = `factorio-icon factorio-${tagName}--${sanitizeCssValue(value)}`;
  return `<i class="${cls}" aria-hidden="true">${escapeHtml(value)}</i>`;
}

function renderIconTag(tagName: string, rawValue: string | undefined): string {
  if (rawValue === undefined) {
    return renderIconElement(tagName, undefined);
  }

  if (QUALITY_AWARE_TAGS.has(tagName)) {
    const qualityIdx = rawValue.indexOf(",quality=");
    if (qualityIdx !== -1) {
      const baseValue = rawValue.slice(0, qualityIdx);
      const tier = rawValue.slice(qualityIdx + ",quality=".length);
      const qualityCls = `factorio-icon factorio-quality--${sanitizeCssValue(tier)} factorio-quality-overlay`;
      const qualityEl = `<i class="${qualityCls}" aria-hidden="true">${escapeHtml(tier)}</i>`;
      return `<span class="factorio-icon-with-quality">${renderIconElement(tagName, baseValue)}${qualityEl}</span>`;
    }
  }

  return renderIconElement(tagName, rawValue);
}

// Group 1: opening tag name | Group 2: value | Group 3: closing tag name
const TAG_RE = /\[([a-z][a-z0-9-]*)(?:=([^\]]*))?\]|\[\/([a-z][a-z0-9-]*)\]/gi;

export function renderRichText(input: string): string {
  let result = "";
  let lastIndex = 0;
  const openTagStack: string[] = [];

  TAG_RE.lastIndex = 0;
  let match: RegExpExecArray | null;

  while ((match = TAG_RE.exec(input)) !== null) {
    result += escapeHtml(input.slice(lastIndex, match.index));
    lastIndex = match.index + match[0].length;

    const [, openTag, value, closeTag] = match;

    if (closeTag !== undefined) {
      const tag = closeTag.toLowerCase();
      const idx = openTagStack.lastIndexOf(tag);
      if (idx !== -1) {
        openTagStack.splice(idx, 1);
        result += "</span>";
      }
    } else {
      const tag = openTag.toLowerCase();

      if (WRAPPING_TAGS.has(tag)) {
        openTagStack.push(tag);
        if (tag === "color") {
          const css = value !== undefined ? parseColor(value) : null;
          result += css !== null ? `<span style="color:${css}">` : "<span>";
        } else if (tag === "font") {
          result += `<span class="factorio-font--${sanitizeCssValue(value ?? "")}">`;
        } else {
          result += "<span>";
        }
      } else if (ICON_TAGS.has(tag)) {
        result += renderIconTag(tag, value);
      } else {
        result += escapeHtml(match[0]);
      }
    }
  }

  result += escapeHtml(input.slice(lastIndex));
  for (let i = openTagStack.length - 1; i >= 0; i--) result += "</span>";

  return result;
}
