# frozen_string_literal: true

module PastaAtlas
  module Views
    module Maps
      class Index < Hanami::View
        expose :maps, :user_profiles_by_id, :page, :per_page, :total
      end
    end
  end
end
