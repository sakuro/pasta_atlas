# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UserProfileRepo < PastaAtlas::DB::Repo
      def find_by_user_id(user_id) = user_profiles.where(user_id:).one!
      def find_by_user_ids(user_ids) = user_profiles.where(user_id: user_ids).to_a
    end
  end
end
