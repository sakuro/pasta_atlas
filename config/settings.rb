# frozen_string_literal: true

module PastaAtlas
  class Settings < Hanami::Settings
    setting :s3_bucket, constructor: Types::String
    setting :cloudfront_base_url, constructor: Types::String
    setting :presigned_url_expiry, default: 3600, constructor: Types::Params::Integer
  end
end
