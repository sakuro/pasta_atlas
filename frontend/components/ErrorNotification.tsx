interface ErrorNotificationProps {
  l10nId: string;
  type?: "danger" | "warning";
}

export const ErrorNotification = (props: ErrorNotificationProps) => (
  <div class={`notification is-${props.type ?? "danger"} is-light`} data-l10n-id={props.l10nId} />
);
