# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Pages
        class Show < PastaAtlas::Action
          include Deps["resolvers.locale_resolver"]

          SLUG_MAP = {
            "about" => "about",
            "privacy" => "privacy_policy",
            "terms" => "terms_of_service"
          }.freeze
          private_constant :SLUG_MAP

          def handle(request, response)
            page_dir = SLUG_MAP[request.params[:slug].to_s]
            halt :not_found unless page_dir

            locale = locale_resolver.call(
              user_id: current_user_id(request),
              accept_language: request.env["HTTP_ACCEPT_LANGUAGE"]
            )
            content_path = resolve_content_path(page_dir, locale)
            json_response(response, {content: content_path.read})
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
