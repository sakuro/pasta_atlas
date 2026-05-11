# frozen_string_literal: true

module PastaAtlas
  module Views
    module Maps
      class Index < Hanami::View
        expose :maps, :user_infos_by_user_id, :map_infos_by_ulid, :page, :per_page, :total
      end
    end
  end
end
