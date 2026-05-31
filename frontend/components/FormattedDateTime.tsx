import { lang, timezone, relativeTimestamps } from "../lib/display-settings";

const formatAbsolute = (dateTime: string): string =>
  new Intl.DateTimeFormat(lang(), {
    year: "numeric", month: "short", day: "numeric",
    hour: "numeric", minute: "numeric",
    timeZone: timezone(),
  }).format(new Date(dateTime));

const formatRelative = (dateTime: string): string => {
  const diff = Math.round((Date.now() - new Date(dateTime).getTime()) / 1000);
  const abs = Math.abs(diff);
  const fmt = new Intl.RelativeTimeFormat(lang(), { style: "long", numeric: "auto" });
  if (abs < 60) return fmt.format(-diff, "second");
  if (abs < 3600) return fmt.format(-Math.round(diff / 60), "minute");
  if (abs < 86400) return fmt.format(-Math.round(diff / 3600), "hour");
  if (abs < 7 * 86400) return fmt.format(-Math.round(diff / 86400), "day");
  if (abs < 30 * 86400) return fmt.format(-Math.round(diff / (7 * 86400)), "week");
  if (abs < 365 * 86400) return fmt.format(-Math.round(diff / (30 * 86400)), "month");
  return fmt.format(-Math.round(diff / (365 * 86400)), "year");
};

type Props = { dateTime: string };

export const FormattedDateTime = (props: Props) => {
  const display = () => relativeTimestamps() ? formatRelative(props.dateTime) : formatAbsolute(props.dateTime);
  const tooltip = () => relativeTimestamps() ? formatAbsolute(props.dateTime) : formatRelative(props.dateTime);
  return (
    <span class="icon-text">
      <span class="icon is-small"><i class="fa-regular fa-calendar" /></span>
      <time datetime={props.dateTime} title={tooltip()}>{display()}</time>
    </span>
  );
};
