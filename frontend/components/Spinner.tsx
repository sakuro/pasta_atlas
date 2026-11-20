interface SpinnerProps {
  size?: "large";
}

export const Spinner = (props: SpinnerProps) => (
  <span class={["icon", { "is-large": props.size === "large" }]}>
    <i class={["fa-solid fa-spinner fa-spin", { "fa-2x": props.size === "large" }]} />
  </span>
);
