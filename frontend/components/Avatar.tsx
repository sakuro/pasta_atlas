type Props = {
  url: string | null;
  size: number;
};

export const Avatar = (props: Props) => (
  props.url
    ? <img src={props.url} width={props.size} height={props.size} style="border-radius:50%" />
    : <i class="fa-solid fa-circle-user" style={`font-size:${props.size}px`} />
);
