# frozen_string_literal: true

module PastaAtlas
  module Views
    module Maps
      class Viewer < Hanami::View
        expose :ulid, :display_name, :author_info, :updated_at, :viewer_name
      end
    end
  end
end
