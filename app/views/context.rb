# auto_register: false
# frozen_string_literal: true

require "rack/protection"

module PastaAtlas
  module Views
    class Context < Hanami::View::Context
      include Deps["repos.user_repo", "repos.user_profile_repo"]

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

      def omniauth_authenticity_token
        Rack::Protection::AuthenticityToken.token(session)
      end
    end
  end
end
