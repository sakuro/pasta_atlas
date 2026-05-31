import { DOMLocalization } from "@fluent/dom";
import { FluentBundle, FluentResource } from "@fluent/bundle";

const SUPPORTED_LOCALES = ["cs", "en", "ja", "ko", "zh-CN", "zh-TW"];

function buildLocaleChain(): string[] {
  const preferred = document.documentElement.lang;
  const candidates = [preferred, ...navigator.languages];
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

l10n.connectRoot(document.documentElement);
