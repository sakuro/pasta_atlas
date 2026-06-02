import { createResource, Show } from "solid-js";
import { lang } from "../lib/display-settings";
import { SpinnerBlock } from "../components/SpinnerBlock";
import { ErrorNotification } from "../components/ErrorNotification";

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
        <SpinnerBlock />
      </Show>
      <Show when={content.error}>
        <ErrorNotification l10nId="error-load-failed" />
      </Show>
      <Show when={!content.error && content()} keyed>
        {/* eslint-disable-next-line solid/no-innerhtml -- content is admin-authored static pages only */}
        {(html) => <div innerHTML={html} />}
      </Show>
    </>
  );
};
