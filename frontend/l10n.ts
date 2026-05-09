import { DOMLocalization } from "@fluent/dom";
import { FluentBundle, FluentResource } from "@fluent/bundle";

const locale = document.documentElement.lang || "en";

async function* generateBundles(resourceIds: ReadonlyArray<string>) {
  const bundle = new FluentBundle(locale);
  for (const resourceId of resourceIds) {
    const response = await fetch(resourceId);
    const text = await response.text();
    bundle.addResource(new FluentResource(text));
  }
  yield bundle;
}

export const l10n = new DOMLocalization(
  [`/assets/messages.${locale}.ftl`],
  generateBundles
);

l10n.connectRoot(document.documentElement);
