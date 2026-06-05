import { createSignal } from "solid-js";
import { SUPPORTED_LOCALES, setLocale } from "./l10n";

const resolveLocale = (locale: string | null): string => {
  if (locale && SUPPORTED_LOCALES.includes(locale)) return locale;
  return navigator.languages.find((l) => SUPPORTED_LOCALES.includes(l)) ?? "en";
};

const resolveTimezone = (tz: string | null): string =>
  tz ?? Intl.DateTimeFormat().resolvedOptions().timeZone;

export const [lang, setLang] = createSignal("en");
export const [timezone, setTimezone] = createSignal(resolveTimezone(null));
export const [relativeTimestamps, setRelativeTimestamps] = createSignal(false);

export const applyPreferences = (locale: string | null, tz: string | null, relative: boolean): void => {
  const resolved = resolveLocale(locale);
  setLocale(resolved);
  setLang(resolved);
  setTimezone(resolveTimezone(tz));
  setRelativeTimestamps(relative);
};
