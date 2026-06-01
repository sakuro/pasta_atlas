# auto_register: false
# frozen_string_literal: true

require "dry/monads"
require "dry/operation"

module PastaAtlas
  class Operation < Dry::Operation
    include Dry::Monads[:result]

    # Reject: Unicode whitespace except regular space (U+0020), C0/C1 control characters (\p{Cc}),
    # and format characters (\p{Cf}) EXCEPT:
    #   U+200D  ZWJ — joins multi-codepoint emoji sequences (e.g. 👨‍💻, 🏳️‍🌈)
    #   U+FE00–U+FE0F  Variation Selectors 1–16 — emoji/text presentation (e.g. ❤️)
    #   U+E0100–U+E01EF  Variation Selectors Supplement — CJK ideograph variants
    DISALLOWED_CHARS = /[[\p{Space}&&[^\u{0020}]]\p{Cc}]|[\p{Cf}&&[^\u{200D}\u{FE00}-\u{FE0F}\u{E0100}-\u{E01EF}]]/
    private_constant :DISALLOWED_CHARS

    private def grapheme_clusters_exceed?(string, limit) = string.scan(/\X/).length > limit
  end
end
