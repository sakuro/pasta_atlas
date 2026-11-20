# frozen_string_literal: true

module PastaAtlas
  module Values
    # An upload that was never completed, with what is needed to remove its generation and S3 prefix.
    StaleUpload = Data.define(:generation_id, :user_name, :mapshot_map_id, :mapshot_unique_id)
  end
end
