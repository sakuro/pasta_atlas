import { createMemo, Errored, isPending, Loading, Show } from "solid-js";
import { lang } from "../lib/display-settings";
import { SpinnerBlock } from "../components/SpinnerBlock";
import { ErrorNotification } from "../components/ErrorNotification";

export const StaticPage = (props: { slug: string }) => {
  const content = createMemo(async () => {
    const slug = props.slug;
    // The server picks the page language from the user's locale, so a locale change refetches.
    lang();
    const res = await fetch(`/api/v1/pages/${slug}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const json = (await res.json()) as { content: string };
    return json.content;
  });

  return (
    <Errored fallback={<ErrorNotification l10nId="error-load-failed" />}>
      <Loading fallback={<SpinnerBlock />}>
        <Show when={isPending(() => content())}>
          <SpinnerBlock />
        </Show>
        {/* eslint-disable-next-line solid/no-innerhtml -- content is admin-authored static pages only */}
        <div innerHTML={content()} />
      </Loading>
    </Errored>
  );
};
