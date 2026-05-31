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
            template_dir = SLUG_MAP[request.params[:slug].to_s]
            halt :not_found unless template_dir

            locale = resolve_locale(request, template_dir)
            partial_path = Hanami.app.root.join("app/templates/pages/#{template_dir}/_#{locale}.html.erb")

            json_response(response, {content: partial_path.read})
          end

          private def resolve_locale(request, template_dir)
            tags = (request.env[::Rack::ICU4X::Locale::ENV_KEY] || []).map(&:to_s)
            tags.find {|tag|
              Hanami.app.root.join("app/templates/pages/#{template_dir}/_#{tag}.html.erb").exist?
            } || "en"
          end
        end
      end
    end
  end
end
