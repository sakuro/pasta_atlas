import { DOMLocalization } from "@fluent/dom";
import { FluentBundle, FluentResource } from "@fluent/bundle";

const SUPPORTED_LOCALES = ["en", "ja"];

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

async function* generateBundles(resourceIds: ReadonlyArray<string>) {
  for (const locale of buildLocaleChain()) {
    const bundle = new FluentBundle(locale);
    for (const resourceId of resourceIds) {
      const response = await fetch(`/assets/${resourceId}.${locale}.ftl`);
      bundle.addResource(new FluentResource(await response.text()));
    }
    yield bundle;
  }
}

export const l10n = new DOMLocalization(["messages"], generateBundles);

l10n.connectRoot(document.documentElement);
