import { createSignal } from "solid-js";
import "../../l10n";

type Props = {
  mapPath: string;
  mapName: string;
};

export const ShareButtons = (props: Props) => {
  const [copied, setCopied] = createSignal(false);

  const shareUrl = () => `${window.location.origin}${props.mapPath}`;

  const xUrl = () =>
    `https://x.com/intent/post?url=${encodeURIComponent(shareUrl())}&text=${encodeURIComponent(props.mapName)}`;

  const bskyUrl = () =>
    `https://bsky.app/intent/compose?text=${encodeURIComponent(`${props.mapName} ${shareUrl()}`)}`;

  const redditUrl = () =>
    `https://www.reddit.com/submit?url=${encodeURIComponent(shareUrl())}&title=${encodeURIComponent(props.mapName)}`;

  const handleCopy = async () => {
    await navigator.clipboard.writeText(shareUrl());
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div class="buttons has-addons">
      <a class="button is-small" href={xUrl()} target="_blank" rel="noopener noreferrer" data-l10n-id="share-x">
        <span class="icon is-small"><i class="fa-brands fa-x-twitter"></i></span>
      </a>
      <a class="button is-small" href={bskyUrl()} target="_blank" rel="noopener noreferrer" data-l10n-id="share-bluesky">
        <span class="icon is-small"><i class="fa-brands fa-bluesky"></i></span>
      </a>
      <a class="button is-small" href={redditUrl()} target="_blank" rel="noopener noreferrer" data-l10n-id="share-reddit">
        <span class="icon is-small"><i class="fa-brands fa-reddit-alien"></i></span>
      </a>
      <a class="button is-small" role="button" onClick={handleCopy} data-l10n-id="share-copy-link">
        <span class="icon is-small">
          <i class={copied() ? "fa-solid fa-check" : "fa-solid fa-link"}></i>
        </span>
      </a>
    </div>
  );
};
