// @vitest-environment node
import { describe, it, expect } from "vitest";
import { renderRichText } from "./richtext";

describe("renderRichText", () => {
  describe("plain text", () => {
    it("returns empty string unchanged", () => {
      expect(renderRichText("")).toBe("");
    });

    it("returns plain text unchanged", () => {
      expect(renderRichText("Iron Ore Station")).toBe("Iron Ore Station");
    });

    it("preserves whitespace", () => {
      expect(renderRichText("  leading and trailing  ")).toBe("  leading and trailing  ");
    });
  });

  describe("HTML escaping", () => {
    it("escapes < and >", () => {
      expect(renderRichText("<b>bold</b>")).toBe("&lt;b&gt;bold&lt;/b&gt;");
    });

    it("escapes &", () => {
      expect(renderRichText("A & B")).toBe("A &amp; B");
    });

    it("escapes double quotes", () => {
      expect(renderRichText('Say "hello"')).toBe("Say &quot;hello&quot;");
    });

    it("escapes single quotes", () => {
      expect(renderRichText("It's a test")).toBe("It&#39;s a test");
    });
  });

  describe("icon tags", () => {
    it("renders [item=iron-ore]", () => {
      expect(renderRichText("[item=iron-ore]")).toBe(
        '<i class="factorio-icon factorio-item--iron-ore" aria-hidden="true">iron-ore</i>'
      );
    });

    it("renders [entity=assembling-machine-1]", () => {
      expect(renderRichText("[entity=assembling-machine-1]")).toBe(
        '<i class="factorio-icon factorio-entity--assembling-machine-1" aria-hidden="true">assembling-machine-1</i>'
      );
    });

    it("renders [fluid=crude-oil]", () => {
      expect(renderRichText("[fluid=crude-oil]")).toBe(
        '<i class="factorio-icon factorio-fluid--crude-oil" aria-hidden="true">crude-oil</i>'
      );
    });

    it("renders [technology=automation]", () => {
      expect(renderRichText("[technology=automation]")).toBe(
        '<i class="factorio-icon factorio-technology--automation" aria-hidden="true">automation</i>'
      );
    });

    it("renders [recipe=advanced-circuit]", () => {
      expect(renderRichText("[recipe=advanced-circuit]")).toBe(
        '<i class="factorio-icon factorio-recipe--advanced-circuit" aria-hidden="true">advanced-circuit</i>'
      );
    });

    it("renders [item-group=combat]", () => {
      expect(renderRichText("[item-group=combat]")).toBe(
        '<i class="factorio-icon factorio-item-group--combat" aria-hidden="true">combat</i>'
      );
    });

    it("renders [virtual-signal=signal-red]", () => {
      expect(renderRichText("[virtual-signal=signal-red]")).toBe(
        '<i class="factorio-icon factorio-virtual-signal--signal-red" aria-hidden="true">signal-red</i>'
      );
    });

    it("renders [achievement=so-long-and-thanks-for-all-the-fish]", () => {
      expect(renderRichText("[achievement=so-long-and-thanks-for-all-the-fish]")).toBe(
        '<i class="factorio-icon factorio-achievement--so-long-and-thanks-for-all-the-fish" aria-hidden="true">so-long-and-thanks-for-all-the-fish</i>'
      );
    });

    it("renders [planet=nauvis]", () => {
      expect(renderRichText("[planet=nauvis]")).toBe(
        '<i class="factorio-icon factorio-planet--nauvis" aria-hidden="true">nauvis</i>'
      );
    });

    it("renders [space-location=shattered-planet]", () => {
      expect(renderRichText("[space-location=shattered-planet]")).toBe(
        '<i class="factorio-icon factorio-space-location--shattered-planet" aria-hidden="true">shattered-planet</i>'
      );
    });

    it("renders [img=item/iron-ore] with slash sanitized to hyphen", () => {
      expect(renderRichText("[img=item/iron-ore]")).toBe(
        '<i class="factorio-icon factorio-img--item-iron-ore" aria-hidden="true">item/iron-ore</i>'
      );
    });

    it("renders [space-age] with no value", () => {
      expect(renderRichText("[space-age]")).toBe(
        '<i class="factorio-icon factorio-space-age" aria-hidden="true"></i>'
      );
    });

    it("renders [train-stop=5]", () => {
      expect(renderRichText("[train-stop=5]")).toBe(
        '<i class="factorio-icon factorio-train-stop--5" aria-hidden="true">5</i>'
      );
    });

    it("renders [gps=100,200]", () => {
      expect(renderRichText("[gps=100,200]")).toBe(
        '<i class="factorio-icon factorio-gps--100-200" aria-hidden="true">100,200</i>'
      );
    });

    it("HTML-escapes icon value in text content", () => {
      expect(renderRichText("[item=a<b]")).toBe(
        '<i class="factorio-icon factorio-item--a-b" aria-hidden="true">a&lt;b</i>'
      );
    });

    it("handles empty value", () => {
      expect(renderRichText("[item=]")).toBe(
        '<i class="factorio-icon factorio-item--" aria-hidden="true"></i>'
      );
    });

    it("is case-insensitive for tag names", () => {
      expect(renderRichText("[Item=iron-ore]")).toBe(renderRichText("[item=iron-ore]"));
    });
  });

  describe("quality modifier", () => {
    it("renders [item=iron-ore,quality=legendary] as two icons", () => {
      expect(renderRichText("[item=iron-ore,quality=legendary]")).toBe(
        '<i class="factorio-icon factorio-item--iron-ore" aria-hidden="true">iron-ore</i>' +
        '<i class="factorio-icon factorio-quality--legendary" aria-hidden="true">legendary</i>'
      );
    });

    it("renders [entity=tank,quality=rare] as two icons", () => {
      expect(renderRichText("[entity=tank,quality=rare]")).toBe(
        '<i class="factorio-icon factorio-entity--tank" aria-hidden="true">tank</i>' +
        '<i class="factorio-icon factorio-quality--rare" aria-hidden="true">rare</i>'
      );
    });

    it("renders standalone [quality=uncommon] as a single icon", () => {
      expect(renderRichText("[quality=uncommon]")).toBe(
        '<i class="factorio-icon factorio-quality--uncommon" aria-hidden="true">uncommon</i>'
      );
    });
  });

  describe("color wrapping tag", () => {
    it("renders named color", () => {
      expect(renderRichText("[color=red]text[/color]")).toBe(
        '<span style="color:red">text</span>'
      );
    });

    it("renders float RGB color", () => {
      expect(renderRichText("[color=0.5,0,0]text[/color]")).toBe(
        '<span style="color:rgba(128,0,0,1)">text</span>'
      );
    });

    it("renders float RGBA color", () => {
      expect(renderRichText("[color=1,0,0,0.5]text[/color]")).toBe(
        '<span style="color:rgba(255,0,0,0.5)">text</span>'
      );
    });

    it("renders #rrggbb hex color", () => {
      expect(renderRichText("[color=#ff0000]text[/color]")).toBe(
        '<span style="color:#ff0000">text</span>'
      );
    });

    it("renders #aarrggbb Factorio ARGB hex color", () => {
      const result = renderRichText("[color=#80ff0000]text[/color]");
      // aa=0x80=128, alpha=128/255≈0.502
      expect(result).toMatch(/^<span style="color:rgba\(255,0,0,0\.\d+\)">text<\/span>$/);
      expect(result).toContain("rgba(255,0,0,");
    });

    it("auto-closes unclosed color tag", () => {
      expect(renderRichText("[color=red]text")).toBe(
        '<span style="color:red">text</span>'
      );
    });

    it("uses plain span for unknown color format", () => {
      expect(renderRichText("[color=not-a-color-123!]text[/color]")).toBe(
        "<span>text</span>"
      );
    });

    it("escapes text content inside color span", () => {
      expect(renderRichText("[color=red]<b>[/color]")).toBe(
        '<span style="color:red">&lt;b&gt;</span>'
      );
    });
  });

  describe("font wrapping tag", () => {
    it("renders font tag", () => {
      expect(renderRichText("[font=default-bold]text[/font]")).toBe(
        '<span class="factorio-font--default-bold">text</span>'
      );
    });

    it("auto-closes unclosed font tag", () => {
      expect(renderRichText("[font=default-semibold]x")).toBe(
        '<span class="factorio-font--default-semibold">x</span>'
      );
    });
  });

  describe("tooltip wrapping tag", () => {
    it("wraps content in plain span", () => {
      expect(renderRichText("[tooltip=some,tip.key]text[/tooltip]")).toBe(
        "<span>text</span>"
      );
    });
  });

  describe("nesting and stacking", () => {
    it("renders nested color and font", () => {
      expect(renderRichText("[color=red][font=default-bold]styled[/font][/color]")).toBe(
        '<span style="color:red"><span class="factorio-font--default-bold">styled</span></span>'
      );
    });

    it("discards unmatched closer", () => {
      expect(renderRichText("[/color]text")).toBe("text");
    });

    it("auto-closes multiple unclosed tags", () => {
      expect(renderRichText("[color=red][font=bold]x")).toBe(
        '<span style="color:red"><span class="factorio-font--bold">x</span></span>'
      );
    });
  });

  describe("unknown tags", () => {
    it("outputs unknown tag as escaped literal text", () => {
      expect(renderRichText("[unknown=foo]")).toBe("[unknown=foo]");
    });

    it("outputs unknown tag without value as escaped literal text", () => {
      expect(renderRichText("[capsule]")).toBe("[capsule]");
    });
  });

  describe("mixed content", () => {
    it("renders icon followed by text", () => {
      expect(renderRichText("[item=iron-ore] Iron Station")).toBe(
        '<i class="factorio-icon factorio-item--iron-ore" aria-hidden="true">iron-ore</i> Iron Station'
      );
    });

    it("renders multiple consecutive icons", () => {
      expect(renderRichText("[item=iron-ore][item=copper-ore]")).toBe(
        '<i class="factorio-icon factorio-item--iron-ore" aria-hidden="true">iron-ore</i>' +
        '<i class="factorio-icon factorio-item--copper-ore" aria-hidden="true">copper-ore</i>'
      );
    });

    it("renders icons embedded in text", () => {
      const result = renderRichText("Craft [item=iron-plate] here");
      expect(result).toBe(
        'Craft <i class="factorio-icon factorio-item--iron-plate" aria-hidden="true">iron-plate</i> here'
      );
    });

    it("renders icon inside color span", () => {
      expect(renderRichText("[color=blue][item=water][/color]")).toBe(
        '<span style="color:blue"><i class="factorio-icon factorio-item--water" aria-hidden="true">water</i></span>'
      );
    });
  });
});
