# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UserPreferenceRepo < PastaAtlas::DB::Repo
      def create(user_id:, timezone:) = user_preferences.command(:create).call(user_id:, timezone:)
      def fetch_by_user_id(user_id) = user_preferences.where(user_id:).one!
      def update_preferences(user_id, timezone:, locale:, relative_timestamps:) = user_preferences.where(user_id:).command(:update).call(timezone:, locale:, relative_timestamps:)

      # INSERT ... ON CONFLICT cannot be written with a ROM command.
      def find_or_create_by_user_id(user_id:)
        user_preferences.dataset.insert_conflict(target: :user_id).insert(user_id:)
        user_preferences.where(user_id:).one!
      end
    end
  end
end
