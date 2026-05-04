import { createSignal } from "solid-js";

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
    <div class="is-flex" style="gap:0.75rem">
      <a href={xUrl()} target="_blank" rel="noopener noreferrer" title="Share on X">
        <span class="icon is-small"><i class="fa-brands fa-x-twitter"></i></span>
      </a>
      <a href={bskyUrl()} target="_blank" rel="noopener noreferrer" title="Share on Bluesky">
        <span class="icon is-small"><i class="fa-brands fa-bluesky"></i></span>
      </a>
      <a href={redditUrl()} target="_blank" rel="noopener noreferrer" title="Share on Reddit">
        <span class="icon is-small"><i class="fa-brands fa-reddit-alien"></i></span>
      </a>
      <a role="button" onClick={handleCopy} title="Copy link">
        <span class="icon is-small">
          <i class={copied() ? "fa-solid fa-check" : "fa-solid fa-link"}></i>
        </span>
      </a>
    </div>
  );
};
