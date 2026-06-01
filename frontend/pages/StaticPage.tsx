import { createResource, Show } from "solid-js";
import { lang } from "../lib/display-settings";

export const StaticPage = (props: { slug: string }) => {
  const [content] = createResource(
    () => [props.slug, lang()] as const,
    async ([slug]) => {
      const res = await fetch(`/api/v1/pages/${slug}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const json = await res.json() as { content: string };
      return json.content;
    }
  );

  return (
    <>
      <Show when={content.loading}>
        <div class="has-text-centered py-5">
          <span class="icon"><i class="fa-solid fa-spinner fa-spin" /></span>
        </div>
      </Show>
      <Show when={content.error}>
        <div class="notification is-danger is-light" data-l10n-id="error-load-failed" />
      </Show>
      <Show when={content()} keyed>
        {/* eslint-disable-next-line solid/no-innerhtml -- content is admin-authored static pages only */}
        {(html) => <div innerHTML={html} />}
      </Show>
    </>
  );
};
