# frozen_string_literal: true

Hanami.app.register_provider(:s3, namespace: true) do
  prepare do
    require "aws-sdk-s3"
  end

  start do
    register "client", Aws::S3::Client.new
  end
end
