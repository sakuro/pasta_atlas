# frozen_string_literal: true

module PastaAtlas
  module Resolvers
    class LocaleResolver
      include Deps[
        "locale.supported_locales",
        load_preferences: "operations.user.preferences.load"
      ]

      def call(user_id:, accept_language: nil)
        load_preferences.call(user_id:).value!.locale || negotiate(accept_language)
      end

      private def negotiate(header)
        return "en" unless header

        tags = header.split(",").filter_map {|part| weighted_tag(part) }.sort_by {|_, q| -q }.map(&:first)

        tags.each do |tag|
          return tag if supported_locales.include?(tag)

          lang = tag.split("-").first
          return lang if supported_locales.include?(lang)
        end
        "en"
      end

      # The header is client input, so a part with a malformed q-value is skipped instead of
      # failing the request.
      private def weighted_tag(part)
        tag, *params = part.split(";").map(&:strip)
        return if tag.nil? || tag.empty?

        q_param = params.find {|param| param.start_with?("q=") }
        q = q_param ? Float(q_param.delete_prefix("q="), exception: false) : 1.0
        [tag, q] if q
      end
    end
  end
end
