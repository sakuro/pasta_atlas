# auto_register: false
# frozen_string_literal: true

module PastaAtlas
  module Views
    class Context < Hanami::View::Context
      include Deps["repos.user_repo"]

      def current_user_profile_name
        user_id = session[:user_id]
        return nil unless user_id

        user_repo.find_by_id(user_id).name
      rescue ROM::TupleCountMismatchError
        nil
      end
    end
  end
end
