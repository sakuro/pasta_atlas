# auto_register: false
# frozen_string_literal: true

require "rack/icu4x/locale"
require "rack/protection"

module PastaAtlas
  module Views
    class Context < Hanami::View::Context
      include Deps["repos.user_repo", "repos.user_profile_repo", "settings"]

      def initialize(i18n: nil, **args)
        super(**args)
        @i18n = i18n
      end

      attr_reader :i18n

      def locale_tag
        locales = request&.env&.[](Rack::ICU4X::Locale::ENV_KEY)
        locales&.first&.to_s || "en"
      end

      def locale_name(locale_code) = ICU4X::DisplayNames.new(ICU4X::Locale.parse(locale_tag), type: :language).of(locale_code.to_s)

      def t(key, **args)
        return key.to_s unless i18n

        id, attr = key.to_s.split(".", 2)
        unless attr
          return i18n.format(id, **args)
        end

        bundle = i18n.find(id)
        return key.to_s unless bundle

        message = bundle.message(id)
        attr_pattern = message&.attributes&.[](attr)
        return key.to_s unless attr_pattern

        bundle.format_pattern(attr_pattern, nil, **args)
      end

      def current_user_name
        user_id = session[:user_id]
        return nil unless user_id

        user_repo.find_by_id(user_id).name
      rescue ROM::TupleCountMismatchError
        nil
      end

      def current_user_display_name
        user_id = session[:user_id]
        return nil unless user_id

        profile = user_profile_repo.find_by_user_id(user_id)
        profile.display_name || user_repo.find_by_id(user_id).name
      rescue ROM::TupleCountMismatchError
        nil
      end

      def current_avatar_url
        user_id = session[:user_id]
        return nil unless user_id

        profile = user_profile_repo.find_by_user_id(user_id)
        return nil unless profile.avatar_s3_key

        "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}"
      rescue ROM::TupleCountMismatchError
        nil
      end

      def omniauth_authenticity_token
        Rack::Protection::AuthenticityToken.token(session)
      end

      def tech_stack_list
        formatter = ICU4X::ListFormat.new(ICU4X::Locale.parse(locale_tag), type: :conjunction, length: :wide)
        url_by_name = TECH_STACK.to_h {|item| [item[:name], item[:url]] }
        formatter.format_to_parts(TECH_STACK.map {|item| item[:name] }).map {|part|
          if part.type == :element
            %(<a href="#{url_by_name[part.value]}" target="_blank" rel="noopener">#{part.value}</a>)
          else
            part.value
          end
        }.join
      end

      TECH_STACK = [
        {name: "Ruby", url: "https://www.ruby-lang.org/"},
        {name: "Hanami", url: "https://hanakai.org/hanami"},
        {name: "SolidJS", url: "https://www.solidjs.com/"},
        {name: "Bulma", url: "https://bulma.io/"},
        {name: "Leaflet", url: "https://leafletjs.com/"},
        {name: "Font Awesome", url: "https://fontawesome.com/"}
      ].freeze
      private_constant :TECH_STACK
    end
  end
end
