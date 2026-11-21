# frozen_string_literal: true

# The settings are loaded before lib/ is autoloaded.
require_relative "../lib/pasta_atlas/types"

module PastaAtlas
  class Settings < Hanami::Settings
    setting :session_secret, constructor: Types::String
    setting :discord_client_id, constructor: Types::String
    setting :discord_client_secret, constructor: Types::String
    setting :github_client_id, constructor: Types::String
    setting :github_client_secret, constructor: Types::String
    setting :steam_web_api_key, constructor: Types::String
    setting :aws_region, default: "ap-northeast-1", constructor: Types::String
    setting :s3_bucket, constructor: Types::String
    # Settings has its own Types constant (Hanami's), so the application's types are qualified.
    cloudfront_base_url_type = Hanami.env?(:development, :test) ? PastaAtlas::Types::HTTPURL : PastaAtlas::Types::HTTPSURL
    setting :cloudfront_base_url, constructor: cloudfront_base_url_type
    setting :presigned_url_expiry, default: 3600, constructor: Types::Params::Integer
    setting :stale_upload_days, default: 7, constructor: Types::Params::Integer
    setting :sqs_s3_cleanup_queue_url, constructor: Types::String
  end
end
