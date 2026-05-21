# frozen_string_literal: true

module PastaAtlas
  module Views
    module Maps
      class Index < Hanami::View
        expose :map_infos, :page, :per_page, :total, :flash_notice
      end
    end
  end
end
