interface SpinnerProps {
  size?: "large";
}

export const Spinner = (props: SpinnerProps) => (
  <span class={`icon${props.size === "large" ? " is-large" : ""}`}>
    <i class={`fa-solid fa-spinner fa-spin${props.size === "large" ? " fa-2x" : ""}`} />
  </span>
);
