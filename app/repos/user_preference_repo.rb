# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UserPreferenceRepo < PastaAtlas::DB::Repo
      def find_by_user_id(user_id) = user_preferences.where(user_id:).one!
      def update_preferences(user_id, timezone:, locale:) = user_preferences.where(user_id:).command(:update).call(timezone:, locale:)
    end
  end
end
