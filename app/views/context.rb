# auto_register: false
# frozen_string_literal: true

require "rack/icu4x/locale"
require "rack/protection"

module PastaAtlas
  module Views
    class Context < Hanami::View::Context
      include Deps["repos.user_preference_repo", "repos.user_repo", "routes"]

      def path(...) = routes.path(...)
      def url(...) = routes.url(...)

      def locale_tag = locale.to_s

      def omniauth_authenticity_token
        Rack::Protection::AuthenticityToken.token(session)
      end

      def viewer_relative_timestamps? = viewer_preference&.relative_timestamps || false

      def viewer_timezone = viewer_preference&.timezone || "UTC"

      private def locale = request.env[Rack::ICU4X::Locale::ENV_KEY].first

      private def viewer_preference
        @viewer_preference ||= begin
          user_id = session[:user_id] || user_repo.find_by_name("guest").id
          user_preference_repo.find_by_user_id(user_id)
        rescue ROM::TupleCountMismatchError
          nil
        end
      end
    end
  end
end
