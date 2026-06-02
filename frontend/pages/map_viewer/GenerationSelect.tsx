import { For } from "solid-js";
import { formatTicks } from "../../lib/format-ticks";
import { lang } from "../../lib/display-settings";

interface GenerationSelectItem {
  ulid: string;
  tick: number;
}

interface GenerationSelectProps {
  generations: GenerationSelectItem[];
  value: string;
  onChange: (ulid: string) => void;
}

export const GenerationSelect = (props: GenerationSelectProps) => (
  <div class="control has-icons-left" style={{ "flex-shrink": 0 }}>
    <div class="select is-small">
      <select
        value={props.value}
        onChange={(e) => props.onChange(e.currentTarget.value)}
      >
        <For each={props.generations}>
          {(gen) => (
            <option value={gen.ulid}>{formatTicks(gen.tick, lang())}</option>
          )}
        </For>
      </select>
    </div>
    <span class="icon is-small is-left"><i class="fa-solid fa-timeline" /></span>
  </div>
);
