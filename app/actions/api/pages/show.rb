# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Pages
        class Show < PastaAtlas::Action
          SLUG_MAP = {
            "about" => "about",
            "privacy" => "privacy_policy",
            "terms" => "terms_of_service"
          }.freeze
          private_constant :SLUG_MAP

          def handle(request, response)
            page_dir = SLUG_MAP[request.params[:slug].to_s]
            halt :not_found unless page_dir

            locale = resolve_locale(request, page_dir)
            content_path = Hanami.app.root.join("app/page_content/#{page_dir}/#{locale}.html")

            json_response(response, {content: content_path.read})
          end

          private def resolve_locale(request, page_dir)
            tags = (request.env[::Rack::ICU4X::Locale::ENV_KEY] || []).map(&:to_s)
            tags.find {|tag|
              Hanami.app.root.join("app/page_content/#{page_dir}/#{tag}.html").exist?
            } || "en"
          end
        end
      end
    end
  end
end
