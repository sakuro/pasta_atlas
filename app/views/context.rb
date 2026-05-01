# auto_register: false
# frozen_string_literal: true

module PastaAtlas
  module Views
    class Context < Hanami::View::Context
      include Deps["repos.user_profile_repo"]

      def current_user_profile_name
        user_id = session[:user_id]
        return nil unless user_id

        user_profile_repo.find_by_user_id(user_id).name
      rescue
        nil
      end
    end
  end
end
