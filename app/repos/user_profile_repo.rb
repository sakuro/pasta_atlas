# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UserProfileRepo < PastaAtlas::DB::Repo
      def create(user_id:) = user_profiles.command(:create).call(user_id:)
      def find_by_user_id(user_id) = user_profiles.where(user_id:).one!
      def find_by_user_ids(user_ids) = user_profiles.where(user_id: user_ids).to_a
      def update_profile(user_id, display_name:) = user_profiles.where(user_id:).command(:update).call(display_name:)
      def update_avatar(user_id, avatar_s3_key:) = user_profiles.where(user_id:).command(:update).call(avatar_s3_key:)
      def clear_avatar(user_id) = user_profiles.where(user_id:).command(:update).call(avatar_s3_key: nil)
    end
  end
end
