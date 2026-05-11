# frozen_string_literal: true

module PastaAtlas
  module Values
    # Aggregates all display-oriented data needed to render a map card, including embedded UserInfo.
    MapInfo = Data.define(:ulid, :display_name, :user_info, :thumbnail_url, :metadata_url, :updated_at)
  end
end
