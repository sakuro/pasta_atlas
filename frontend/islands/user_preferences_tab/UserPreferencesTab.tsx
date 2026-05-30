import { createResource, createSignal, For, onCleanup, onMount, Show } from "solid-js";
import "../../l10n";

type PreferencesData = {
  timezone: string;
  timezone_identifiers: string[];
  locale: string | null;
  supported_locales: string[];
  relative_timestamps: boolean;
};

const csrfToken = (): string =>
  document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "";

const currentTimeInTz = (tz: string): string =>
  new Intl.DateTimeFormat("en", { timeZone: tz, hour: "2-digit", minute: "2-digit", hour12: false }).format(new Date());

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
    return new Intl.DisplayNames([document.documentElement.lang || "en"], { type: "language" }).of(locale) ?? locale;
  } catch {
    return locale;
  }
};

export const UserPreferencesTab = (props: { userName: string; active: () => boolean }) => {
  const [data] = createResource(props.active, async (isActive) => {
    if (!isActive) return undefined;
    const res = await fetch(`/@${props.userName}/preferences`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json() as Promise<PreferencesData>;
  });

  const [selectedTz, setSelectedTz] = createSignal("");
  const [tzTime, setTzTime] = createSignal("");

  const updateTzTime = () => setTzTime(currentTimeInTz(selectedTz()));

  onMount(() => {
    const now = new Date();
    const msUntilNextMinute = (60 - now.getSeconds()) * 1000 - now.getMilliseconds();
    let intervalId: ReturnType<typeof setInterval>;
    const timeoutId = setTimeout(() => {
      updateTzTime();
      intervalId = setInterval(updateTzTime, 60000);
    }, msUntilNextMinute);
    onCleanup(() => { clearTimeout(timeoutId); clearInterval(intervalId); });
  });

  const onTzChange = (tz: string) => {
    setSelectedTz(tz);
    setTzTime(currentTimeInTz(tz));
  };

  const initTz = (pref: PreferencesData) => {
    setSelectedTz(pref.timezone);
    setTzTime(currentTimeInTz(pref.timezone));
  };

  return (
    <>
      <Show when={data.loading}>
        <div class="has-text-centered py-5">
          <span class="icon"><i class="fa-solid fa-spinner fa-spin" /></span>
        </div>
      </Show>
      <Show when={data.error}>
        <div class="notification is-danger is-light" data-l10n-id="error-load-failed" />
      </Show>
      <Show when={!data.loading && data()} keyed>
        {(pref) => {
          initTz(pref);
          return (
            <form action={`/@${props.userName}/preferences`} method="post">
              <input type="hidden" name="_method" value="patch" />
              <input type="hidden" name="_csrf_token" value={csrfToken()} />
              <input type="hidden" name="user_name" value={props.userName} />
              <div class="field">
                <p class="label">
                  <span class="icon-text">
                    <span class="icon"><i class="fa-solid fa-clock" /></span>
                    <span data-l10n-id="edit-time-display" />
                  </span>
                </p>
                <div class="pl-4">
                  <div class="field">
                    <label class="label is-small" for="timezone-select" data-l10n-id="edit-timezone-label" />
                    <div class="control is-flex is-align-items-center">
                      <div class="select">
                        <select
                          id="timezone-select"
                          name="timezone"
                          value={selectedTz()}
                          onChange={(e) => onTzChange(e.currentTarget.value)}
                        >
                          <For each={groupTimezones(pref.timezone_identifiers)}>
                            {(group) => (
                              <optgroup label={group.region}>
                                <For each={group.timezones}>
                                  {(tz) => <option value={tz} selected={tz === selectedTz()}>{tz}</option>}
                                </For>
                              </optgroup>
                            )}
                          </For>
                        </select>
                      </div>
                      <span class="ml-3">{tzTime()}</span>
                    </div>
                  </div>
                  <div class="field">
                    <div class="control">
                      <input type="hidden" name="relative_timestamps" value="false" />
                      <label class="checkbox">
                        <input
                          type="checkbox"
                          name="relative_timestamps"
                          value="true"
                          checked={pref.relative_timestamps}
                        />
                        {" "}
                        <span data-l10n-id="edit-time-display-relative" />
                      </label>
                    </div>
                  </div>
                </div>
              </div>
              <div class="field">
                <label class="label" for="locale-select">
                  <span class="icon-text">
                    <span class="icon"><i class="fa-solid fa-language" /></span>
                    <span data-l10n-id="edit-locale" />
                  </span>
                </label>
                <div class="control">
                  <div class="select">
                    <select id="locale-select" name="locale">
                      <option value="" selected={!pref.locale} data-l10n-id="edit-locale-use-browser" />
                      <For each={pref.supported_locales}>
                        {(loc) => (
                          <option value={loc} selected={pref.locale === loc}>
                            {localeDisplayName(loc)}
                          </option>
                        )}
                      </For>
                    </select>
                  </div>
                </div>
              </div>
              <div class="field">
                <div class="control">
                  <button class="button is-primary" type="submit">
                    <span class="icon"><i class="fa-solid fa-floppy-disk" /></span>
                    <span data-l10n-id="edit-save-preferences" />
                  </button>
                  <a class="button ml-2" href="/" data-l10n-id="edit-cancel" />
                </div>
              </div>
            </form>
          );
        }}
      </Show>
    </>
  );
};
