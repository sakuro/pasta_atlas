# frozen_string_literal: true

module PastaAtlas
  module Views
    module Maps
      class Viewer < Hanami::View
        expose :ulid, :display_name
      end
    end
  end
end
