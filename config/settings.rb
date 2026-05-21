# frozen_string_literal: true

require "uri"

module PastaAtlas
  class Settings < Hanami::Settings
    setting :session_secret, constructor: Types::String
    setting :discord_client_id, constructor: Types::String
    setting :discord_client_secret, constructor: Types::String
    setting :github_client_id, constructor: Types::String
    setting :github_client_secret, constructor: Types::String
    setting :steam_web_api_key, constructor: Types::String
    setting :s3_bucket, constructor: Types::String
    setting :cloudfront_base_url, constructor: ->(v) {
      uri = URI(v.to_s)
      https_required = !Hanami.env?(:development, :test)
      raise Dry::Types::CoercionError, "cloudfront_base_url must be an HTTPS URL" if https_required && !uri.is_a?(URI::HTTPS)

      uri
    }
    setting :presigned_url_expiry, default: 3600, constructor: Types::Params::Integer
    setting :sqs_map_deletion_queue_url, constructor: Types::String
  end
end
