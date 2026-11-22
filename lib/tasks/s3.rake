# frozen_string_literal: true

namespace :s3 do
  desc "Poll SQS queues and process messages"
  task process_queues: :environment do
    require "concurrent-ruby"
    require_relative "../workers/s3_cleanup_queue_worker"

    $stdout.sync = true
    stop = Concurrent::Event.new

    # Concurrent::Event#set takes a mutex, which Ruby forbids inside a trap handler.
    trap("SIGTERM") { Thread.new { stop.set } }
    trap("SIGINT")  { Thread.new { stop.set } }

    sqs_client = Hanami.app["sqs.client"]
    settings = Hanami.app["settings"]
    wait_time_seconds = Hanami.env?(:development) ? 1 : 20

    S3CleanupQueueWorker.new(sqs_client:, settings:, stop:, wait_time_seconds:).thread.join
  end
end
