export const formatTicks = (tick: number, locale: string, style: "narrow" | "long" | "short" = "short"): string => {
  const totalSeconds = Math.floor(tick / 60);
  const seconds = totalSeconds % 60;
  const totalMinutes = Math.floor(totalSeconds / 60);
  const minutes = totalMinutes % 60;
  const totalHours = Math.floor(totalMinutes / 60);
  const hours = totalHours % 24;
  const days = Math.floor(totalHours / 24);
  return new Intl.DurationFormat(locale, { style }).format({ days, hours, minutes, seconds });
};
