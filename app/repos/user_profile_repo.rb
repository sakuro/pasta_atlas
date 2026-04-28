# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UserProfileRepo < PastaAtlas::DB::Repo
      def find_by_user_id(user_id) = root.where(user_id:).one
    end
  end
end
