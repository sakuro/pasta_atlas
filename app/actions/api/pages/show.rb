# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Pages
        class Show < PastaAtlas::Action
          include Deps[load_preferences: "operations.user.preferences.load"]

          SLUG_MAP = {
            "about" => "about",
            "privacy" => "privacy_policy",
            "terms" => "terms_of_service"
          }.freeze
          private_constant :SLUG_MAP

          def handle(request, response)
            page_dir = SLUG_MAP[request.params[:slug].to_s]
            halt :not_found unless page_dir

            locale = resolve_locale(request)
            content_path = resolve_content_path(page_dir, locale)
            json_response(response, {content: content_path.read})
          end

          private def resolve_locale(request)
            user_id = current_user_id(request)
            if user_id
              load_preferences.call(user_id:).value!.locale
            else
              negotiate_locale(request.env["HTTP_ACCEPT_LANGUAGE"])
            end
          end

          private def negotiate_locale(header)
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

          private def resolve_content_path(page_dir, locale)
            path = Hanami.app.root.join("app/page_content/#{page_dir}/#{locale}.html")
            return path if path.exist?

            Hanami.app.root.join("app/page_content/#{page_dir}/en.html")
          end
        end
      end
    end
  end
end
