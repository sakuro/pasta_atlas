# frozen_string_literal: true

Hanami.app.register_provider(:sqs, namespace: true) do
  prepare do
    require "aws-sdk-sqs"
  end

  start do
    register "client", Aws::SQS::Client.new
  end
end
