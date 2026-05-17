# frozen_string_literal: true

module PastaAtlas
  module Views
    module Maps
      class Viewer < Hanami::View
        expose :ulid, :display_name, :author_name, :author_display_name, :author_avatar_url, :updated_at, :viewer_name
      end
    end
  end
end
