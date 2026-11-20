// @vitest-environment node
import { describe, it, expect } from "vitest";
import { buildShareUrl } from "./share-url";

const origin = "https://pasta-atlas.example";
const mapPath = "/maps/01MAP?generation=01GEN";

describe("buildShareUrl", () => {
  it("returns the map path alone when the location has no query", () => {
    expect(buildShareUrl(origin, mapPath, "")).toBe("https://pasta-atlas.example/maps/01MAP?generation=01GEN");
  });

  it("adds the position and zoom of the current location", () => {
    expect(buildShareUrl(origin, mapPath, "?x=-109.05&y=57.83&z=1.9"))
      .toBe("https://pasta-atlas.example/maps/01MAP?generation=01GEN&x=-109.05&y=57.83&z=1.9");
  });

  it("uses a single question mark when the location already has a generation", () => {
    const url = buildShareUrl(origin, mapPath, "?generation=01GEN&x=1&y=2&z=3");
    expect(url.match(/\?/g)).toHaveLength(1);
    expect(url).toBe("https://pasta-atlas.example/maps/01MAP?generation=01GEN&x=1&y=2&z=3");
  });

  it("prefers the generation of the map path over the one in the location", () => {
    expect(buildShareUrl(origin, mapPath, "?generation=OLD&x=1"))
      .toBe("https://pasta-atlas.example/maps/01MAP?generation=01GEN&x=1");
  });
});
