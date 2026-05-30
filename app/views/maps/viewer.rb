# frozen_string_literal: true

module PastaAtlas
  module Views
    module Maps
      class Viewer < Hanami::View
        expose :ulid, :display_name, :author_info, :updated_at, :thumbnail_url, :viewer_name, decorate: false
        expose(:relative_timestamps, decorate: false) {|context:| context.viewer_relative_timestamps? }
      end
    end
  end
end
