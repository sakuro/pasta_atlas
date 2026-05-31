import { createSignal } from "solid-js";
import { SUPPORTED_LOCALES, setLocale } from "./l10n";

const resolveLocale = (locale: string | null): string => {
  if (locale && SUPPORTED_LOCALES.includes(locale)) return locale;
  return navigator.languages.find((l) => SUPPORTED_LOCALES.includes(l)) ?? "en";
};

export const [lang, setLang] = createSignal("en");
export const [timezone, setTimezone] = createSignal("UTC");
export const [relativeTimestamps, setRelativeTimestamps] = createSignal(false);

export const applyPreferences = (locale: string | null, tz: string, relative: boolean): void => {
  const resolved = resolveLocale(locale);
  setLocale(resolved);
  setLang(resolved);
  setTimezone(tz);
  setRelativeTimestamps(relative);
};
