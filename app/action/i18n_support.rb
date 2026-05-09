# auto_register: false
# frozen_string_literal: true

require "rack/icu4x/locale"

module PastaAtlas
  class Action
    # Prepended into Action to build a per-request Foxtail::Sequence from negotiated locales.
    module I18nSupport
      # @api private
      def handle(request, response)
        @i18n = build_i18n_sequence(request)
        super
      end

      private def i18n = @i18n

      private def build_i18n_sequence(request)
        locales = request.env[Rack::ICU4X::Locale::ENV_KEY]
        bundles = locales.filter_map {|locale| i18n_bundles[locale.to_s] }
        Foxtail::Sequence.new(*bundles)
      end
    end
  end
end
