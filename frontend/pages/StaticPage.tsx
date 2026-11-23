import { createMemo, Errored, isPending, Loading, Show } from "solid-js";
import { lang } from "../lib/display-settings";
import { SpinnerBlock } from "../components/SpinnerBlock";
import { ErrorNotification } from "../components/ErrorNotification";
import { showPage, type ShowPageData } from "../lib/api/client";

export const StaticPage = (props: { slug: ShowPageData["path"]["slug"] }) => {
  const content = createMemo(async () => {
    const slug = props.slug;
    // The server picks the page language from the user's locale, so a locale change refetches.
    lang();
    const { data, error, response } = await showPage({ path: { slug } });
    if (!data) throw new Error(`HTTP ${response?.status}`, { cause: error });
    return data.content;
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
