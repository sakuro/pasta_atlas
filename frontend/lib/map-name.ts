import { adjectives, animals, colors, uniqueNamesGenerator } from "unique-names-generator";

// The server enforces the same limit (MAP_NAME_MAX_GRAPHEME_CLUSTERS).
export const MAX_MAP_NAME_GRAPHEMES = 30;

const segmenter = new Intl.Segmenter();

export const countGraphemes = (s: string): number => [...segmenter.segment(s)].length;

const generateCandidate = (): string => {
  const raw = uniqueNamesGenerator({ dictionaries: [adjectives, colors, animals], separator: " ", style: "lowerCase" });
  return raw.charAt(0).toUpperCase() + raw.slice(1);
};

// About 0.7% of the combinations exceed the limit, so a retry is rarely needed.
export const generateMapName = (): string => {
  for (;;) {
    const name = generateCandidate();
    if (countGraphemes(name) <= MAX_MAP_NAME_GRAPHEMES) return name;
  }
};
