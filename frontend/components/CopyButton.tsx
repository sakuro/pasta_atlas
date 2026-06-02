import { createSignal } from "solid-js";
import type { JSX } from "solid-js";

interface CopyButtonProps {
  text: string;
  l10nId: string;
  class?: string;
  style?: JSX.CSSProperties;
}

export const CopyButton = (props: CopyButtonProps) => {
  const [copied, setCopied] = createSignal(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(props.text).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }).catch(() => {});
  };

  return (
    <button
      class={`button is-small${props.class ? ` ${props.class}` : ""}`}
      style={props.style}
      onClick={handleCopy}
      data-l10n-id={props.l10nId}
    >
      <span class="icon is-small">
        <i class={copied() ? "fa-solid fa-check has-text-success" : "fa-regular fa-copy"} />
      </span>
    </button>
  );
};
