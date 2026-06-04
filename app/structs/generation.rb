# frozen_string_literal: true

module PastaAtlas
  module Structs
    class Generation < PastaAtlas::DB::Struct
    end

    class Generation
      def metadata_url(base_url) = "#{base_url}/#{metadata_s3_key}"
      def thumbnail_url(base_url) = "#{base_url}/#{metadata_s3_key.sub("mapshot.json", "s1zoom_4/tile_0_0.jpg")}"
    end
  end
end
