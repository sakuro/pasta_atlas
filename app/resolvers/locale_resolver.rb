# frozen_string_literal: true

module PastaAtlas
  module Resolvers
    class LocaleResolver
      include Deps[load_preferences: "operations.user.preferences.load"]

      def call(user_id:, accept_language: nil)
        if user_id
          load_preferences.call(user_id:).value!.locale
        else
          negotiate(accept_language)
        end
      end

      private def negotiate(header)
        return "en" unless header

        tags = header.split(",").filter_map {|part|
          tag, q = part.strip.split(";q=")
          [tag.strip, Float(q || "1")]
        }.sort_by {|_, q| -q }.map(&:first)

        tags.each do |tag|
          return tag if PastaAtlas::I18n::SUPPORTED_LOCALES.include?(tag)

          lang = tag.split("-").first
          return lang if PastaAtlas::I18n::SUPPORTED_LOCALES.include?(lang)
        end
        "en"
      end
    end
  end
end
