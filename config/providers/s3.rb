# frozen_string_literal: true

Hanami.app.register_provider(:s3, namespace: true) do
  prepare do
    require "aws-sdk-s3"
  end

  start do
    # force_path_style is required when using a local S3-compatible endpoint
    # (e.g. Floci/LocalStack) because virtual-hosted style DNS cannot resolve.
    options = ENV.key?("AWS_ENDPOINT_URL") ? {force_path_style: true} : {}
    register "client", Aws::S3::Client.new(**options)
  end
end
