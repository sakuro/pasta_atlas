# frozen_string_literal: true

module PastaAtlas
  module Views
    module Profile
      class Show < Hanami::View
        expose :user_name, :display_name, :own_profile, :avatar_url, :recent_maps, :thumbnail_urls_by_map_ulid, :metadata_urls_by_map_ulid
      end
    end
  end
end
