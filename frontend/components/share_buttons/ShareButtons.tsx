import { createSignal } from "solid-js";
import "../../lib/l10n";

type Props = {
  mapPath: string;
  mapName: string;
};

export const ShareButtons = (props: Props) => {
  const [copied, setCopied] = createSignal(false);

  const shareUrl = () => `${window.location.origin}${props.mapPath}${window.location.search}`;

  const openShare = (url: string) => window.open(url, "_blank", "noopener,noreferrer");

  const handleCopy = async () => {
    await navigator.clipboard.writeText(shareUrl());
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div class="buttons has-addons">
      <button class="button is-small" onClick={() => openShare(`https://x.com/intent/post?url=${encodeURIComponent(shareUrl())}&text=${encodeURIComponent(props.mapName)}&hashtags=Factorio,PastaAtlas`)} data-l10n-id="share-x">
        <span class="icon is-small"><i class="fa-brands fa-x-twitter" /></span>
      </button>
      <button class="button is-small" onClick={() => openShare(`https://bsky.app/intent/compose?text=${encodeURIComponent(`${props.mapName} ${shareUrl()}`)}`)} data-l10n-id="share-bluesky">
        <span class="icon is-small"><i class="fa-brands fa-bluesky" /></span>
      </button>
      <button class="button is-small" onClick={() => openShare(`https://www.reddit.com/submit?url=${encodeURIComponent(shareUrl())}&title=${encodeURIComponent(props.mapName)}`)} data-l10n-id="share-reddit">
        <span class="icon is-small"><i class="fa-brands fa-reddit-alien" /></span>
      </button>
      <button class="button is-small" onClick={handleCopy} data-l10n-id="share-copy-link">
        <span class="icon is-small">
          <i class={copied() ? "fa-solid fa-check" : "fa-solid fa-link"} />
        </span>
      </button>
    </div>
  );
};
