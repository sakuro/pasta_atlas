import { createMemo, createSignal, Errored, For, Loading, onSettled, Show } from "solid-js";
import { l10n, SUPPORTED_LOCALES } from "../../lib/l10n";
import { applyPreferences, lang } from "../../lib/display-settings";
import { SpinnerBlock } from "../../components/SpinnerBlock";
import { ErrorNotification } from "../../components/ErrorNotification";

type PreferencesData = {
  timezone: string | null;
  timezone_identifiers: string[];
  locale: string | null;
  relative_timestamps: boolean;
};

const csrfToken = (): string => document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "";

const browserTimezone = (): string => Intl.DateTimeFormat().resolvedOptions().timeZone;

const currentTimeInTz = (tz: string | null): string =>
  new Intl.DateTimeFormat("en", {
    timeZone: tz ?? browserTimezone(),
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).format(new Date());

const groupTimezones = (identifiers: string[]): { region: string; timezones: string[] }[] => {
  const groups = new Map<string, string[]>();
  for (const tz of identifiers) {
    const region = tz.includes("/") ? tz.split("/")[0] : "Other";
    if (!groups.has(region)) groups.set(region, []);
    groups.get(region)!.push(tz);
  }
  return Array.from(groups, ([region, timezones]) => ({ region, timezones }));
};

const localeDisplayName = (locale: string): string => {
  try {
    const inCurrentLang = new Intl.DisplayNames([lang()], { type: "language" }).of(locale) ?? locale;
    const inOwnLang = new Intl.DisplayNames([locale], { type: "language" }).of(locale) ?? locale;
    return inCurrentLang === inOwnLang ? inCurrentLang : `${inCurrentLang} (${inOwnLang})`;
  } catch {
    return locale;
  }
};

export const UserPreferencesTab = (props: {
  userName: string;
  active: () => boolean;
  onSuccess?: () => void;
  onError?: (msgKey: string) => void;
}) => {
  const data = createMemo(async (): Promise<PreferencesData | undefined> => {
    if (!props.active()) return undefined;
    const res = await fetch(`/api/v1/users/${props.userName}/preferences`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json() as Promise<PreferencesData>;
  });

  // Form drafts seeded from the fetched preferences; re-seeded if they are refetched.
  const [selectedLocale, setSelectedLocale] = createSignal<string | null>(() => data()?.locale ?? null);
  const [selectedTz, setSelectedTz] = createSignal<string | null>(() => data()?.timezone ?? null);
  const [relativeTimestamps, setRelativeTimestamps] = createSignal(() => data()?.relative_timestamps ?? false);
  const [submitting, setSubmitting] = createSignal(false);

  // Bumped at each minute boundary so the clock next to the timezone select stays current.
  const [minuteTick, setMinuteTick] = createSignal(0);
  const tzTime = () => {
    minuteTick();
    return currentTimeInTz(selectedTz());
  };
  const updateTzTime = () => setMinuteTick((n) => n + 1);

  onSettled(() => {
    const now = new Date();
    const msUntilNextMinute = (60 - now.getSeconds()) * 1000 - now.getMilliseconds();
    let intervalId: ReturnType<typeof setInterval> | undefined;
    const timeoutId = setTimeout(() => {
      updateTzTime();
      intervalId = setInterval(updateTzTime, 60000);
    }, msUntilNextMinute);
    return () => {
      clearTimeout(timeoutId);
      clearInterval(intervalId);
    };
  });

  const onTzChange = (tz: string) => {
    setSelectedTz(tz === "" ? null : tz);
  };

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault();
    setSubmitting(true);
    const form = e.currentTarget as HTMLFormElement;
    const formData = new FormData(form);
    const relTs = relativeTimestamps();
    try {
      const res = await fetch(`/api/v1/users/${props.userName}/preferences`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        body: JSON.stringify({
          user_name: props.userName,
          timezone: (formData.get("timezone") as string) || null,
          locale: (formData.get("locale") as string) || null,
          relative_timestamps: String(relTs),
        }),
      });
      if (res.ok) {
        const json = (await res.json()) as { locale: string | null };
        const tz = (formData.get("timezone") as string) || null;
        applyPreferences(json.locale, tz, relTs);
        l10n.onChange();
        props.onSuccess?.();
      } else {
        props.onError?.("error-unknown");
      }
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Errored fallback={<ErrorNotification l10nId="error-load-failed" />}>
      <Loading fallback={<SpinnerBlock />}>
        <Show when={data()} keyed>
          {(pref) => (
            <form onSubmit={(e) => void handleSubmit(e)}>
              <div class="field">
                <p class="label">
                  <span class="icon-text">
                    <span class="icon">
                      <i class="fa-solid fa-clock" />
                    </span>
                    <span data-l10n-id="edit-time-display" />
                  </span>
                </p>
                <div class="pl-4">
                  <div class="field">
                    <label class="label is-small" for="timezone-select" data-l10n-id="edit-timezone-label" />
                    <div class="field has-addons mb-0">
                      <div class="control">
                        <div class="select">
                          <select
                            id="timezone-select"
                            name="timezone"
                            value={selectedTz() ?? ""}
                            onChange={(e) => onTzChange(e.currentTarget.value)}
                          >
                            <option
                              value=""
                              selected={selectedTz() === null}
                              data-l10n-id="edit-timezone-use-browser"
                            />
                            <For each={groupTimezones(pref.timezone_identifiers)}>
                              {(group) => (
                                <optgroup label={group.region}>
                                  <For each={group.timezones}>
                                    {(tz) => (
                                      <option value={tz} selected={tz === selectedTz()}>
                                        {tz}
                                      </option>
                                    )}
                                  </For>
                                </optgroup>
                              )}
                            </For>
                          </select>
                        </div>
                      </div>
                      <div class="control">
                        <span class="button is-static">{tzTime()}</span>
                      </div>
                    </div>
                  </div>
                  <div class="field">
                    <div class="control">
                      <label class="checkbox">
                        <input
                          type="checkbox"
                          checked={relativeTimestamps()}
                          onChange={(e) => setRelativeTimestamps(e.currentTarget.checked)}
                        />{" "}
                        <span data-l10n-id="edit-time-display-relative" />
                      </label>
                    </div>
                  </div>
                </div>
              </div>
              <div class="field">
                <label class="label" for="locale-select">
                  <span class="icon-text">
                    <span class="icon">
                      <i class="fa-solid fa-language" />
                    </span>
                    <span data-l10n-id="edit-locale" />
                  </span>
                </label>
                <div class="pl-4">
                  <div class="control">
                    <div class="select">
                      <select
                        id="locale-select"
                        name="locale"
                        value={selectedLocale() ?? ""}
                        onChange={(e) => setSelectedLocale(e.currentTarget.value || null)}
                      >
                        <option value="" selected={selectedLocale() === null} data-l10n-id="edit-locale-use-browser" />
                        <For each={SUPPORTED_LOCALES}>
                          {(loc) => (
                            <option value={loc} selected={selectedLocale() === loc}>
                              {localeDisplayName(loc)}
                            </option>
                          )}
                        </For>
                      </select>
                    </div>
                  </div>
                </div>
              </div>
              <div class="field">
                <div class="control">
                  <button class="button is-primary" type="submit" disabled={submitting()}>
                    <span class="icon">
                      <i class="fa-solid fa-floppy-disk" />
                    </span>
                    <span data-l10n-id="edit-save-preferences" />
                  </button>
                  <a class="button ml-2" href="/" data-l10n-id="edit-cancel" />
                </div>
              </div>
            </form>
          )}
        </Show>
      </Loading>
    </Errored>
  );
};
