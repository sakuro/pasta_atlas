# frozen_string_literal: true

module PastaAtlas
  module Views
    module Maps
      class Viewer < Hanami::View
        expose :ulid, :display_name, :author_info, :updated_at, :viewer_name, :relative_timestamps, decorate: false
      end
    end
  end
end
