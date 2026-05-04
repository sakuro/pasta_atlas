# frozen_string_literal: true

module PastaAtlas
  module Views
    module Maps
      class Index < Hanami::View
        expose :maps, :users_by_id, :profiles_by_user_id, :avatar_urls_by_user_id, :thumbnail_urls_by_map_ulid, :metadata_urls_by_map_ulid, :page, :per_page, :total
      end
    end
  end
end
