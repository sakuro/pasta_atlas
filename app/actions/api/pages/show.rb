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

            content_path = resolve_content_path(request, page_dir)
            json_response(response, {content: content_path.read})
          end

          private def resolve_content_path(request, page_dir)
            tags = (request.env[::Rack::ICU4X::Locale::ENV_KEY] || []).map(&:to_s)
            tags.each do |tag|
              path = Hanami.app.root.join("app/page_content/#{page_dir}/#{tag}.html")
              return path if path.exist?
            end
            Hanami.app.root.join("app/page_content/#{page_dir}/en.html")
          end
        end
      end
    end
  end
end
