// @vitest-environment node
import { afterEach, describe, expect, it, vi } from "vitest";
import { adjectives, animals, colors } from "unique-names-generator";
import { generateMapName } from "./map-name";

// unique-names-generator picks dictionary[Math.floor(Math.random() * dictionary.length)].
const randomFor = (dictionary: string[], word: string): number => (dictionary.indexOf(word) + 0.5) / dictionary.length;

describe("generateMapName", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("generates again when the name exceeds 30 grapheme clusters", () => {
    vi.spyOn(Math, "random")
      .mockReturnValueOnce(randomFor(adjectives, "straightforward"))
      .mockReturnValueOnce(randomFor(colors, "aquamarine"))
      .mockReturnValueOnce(randomFor(animals, "tyrannosaurus"))
      .mockReturnValueOnce(randomFor(adjectives, "ok"))
      .mockReturnValueOnce(randomFor(colors, "red"))
      .mockReturnValueOnce(randomFor(animals, "ox"));

    expect(generateMapName()).toBe("Ok red ox");
  });
});
