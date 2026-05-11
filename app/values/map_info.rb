# frozen_string_literal: true

module PastaAtlas
  module Values
    # Aggregates display-oriented map data assembled from Generation records for use in view layer.
    MapInfo = Data.define(:thumbnail_url, :metadata_url, :updated_at)
  end
end
