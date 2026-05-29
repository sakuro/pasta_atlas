# frozen_string_literal: true

module PastaAtlas
  module Views
    module Maps
      class Viewer < Hanami::View
        expose :ulid, :display_name, :author_info, :updated_at, :thumbnail_url, :viewer_name, decorate: false
        expose :relative_timestamps, decorate: false

        private def relative_timestamps(context:, relative_timestamps: nil)
          relative_timestamps.nil? ? context.viewer_relative_timestamps : relative_timestamps
        end
      end
    end
  end
end
