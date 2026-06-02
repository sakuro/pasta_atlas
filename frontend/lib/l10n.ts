import { DOMLocalization } from "@fluent/dom";
import { FluentBundle, FluentResource } from "@fluent/bundle";

import SUPPORTED_LOCALES_JSON from "../../config/supported_locales.json";
export const SUPPORTED_LOCALES: string[] = SUPPORTED_LOCALES_JSON;

let currentLocale: string | null = null;
let rootConnected = false;

export function setLocale(locale: string): void {
  currentLocale = locale;
}

export function connectRoot(): void {
  if (rootConnected) return;
  rootConnected = true;
  l10n.connectRoot(document.documentElement);
}

function buildLocaleChain(): string[] {
  const candidates = currentLocale
    ? [currentLocale, ...navigator.languages]
    : [...navigator.languages];
  const seen = new Set<string>();
  return candidates.filter(loc => {
    if (!SUPPORTED_LOCALES.includes(loc) || seen.has(loc)) return false;
    seen.add(loc);
    return true;
  });
}

let ftlManifest: Record<string, { url: string }> | null = null;

async function resolveAssetUrl(key: string): Promise<string> {
  if (!ftlManifest) {
    const res = await fetch("/assets/ftl-manifest.json");
    ftlManifest = res.ok ? await res.json() as Record<string, { url: string }> : {};
  }
  return ftlManifest[key]?.url ?? `/assets/${key}`;
}

async function* generateBundles(resourceIds: ReadonlyArray<string>) {
  for (const locale of buildLocaleChain()) {
    const bundle = new FluentBundle(locale);
    for (const resourceId of resourceIds) {
      const url = await resolveAssetUrl(`${resourceId}.${locale}.ftl`);
      const response = await fetch(url);
      bundle.addResource(new FluentResource(await response.text()));
    }
    yield bundle;
  }
}

export const l10n = new DOMLocalization(["messages"], generateBundles);
