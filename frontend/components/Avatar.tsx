import { Show } from "solid-js";

type Props = {
  url: string | null;
  size: number;
};

export const Avatar = (props: Props) => (
  <Show
    when={props.url}
    fallback={<i class="fa-solid fa-circle-user" style={{ "font-size": `${props.size}px` }} />}
  >
    {(url) => <img src={url()} width={props.size} height={props.size} style={{ "border-radius": "50%" }} />}
  </Show>
);
