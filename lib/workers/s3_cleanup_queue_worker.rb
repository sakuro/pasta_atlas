# frozen_string_literal: true

require_relative "s3_cleanup_processor"
require_relative "sqs_queue_worker"

class S3CleanupQueueWorker < SqsQueueWorker
  def initialize(sqs_client:, settings:, stop:, wait_time_seconds:, processor: nil)
    super(sqs_client:, queue_url: settings.sqs_s3_cleanup_queue_url, stop:, wait_time_seconds:)
    @processor = processor || S3CleanupProcessor.new(operation: Hanami.app["operations.delete_s3_prefix"])
  end

  private def handle(msg)
    return unless @processor.call(msg.body).success?

    @sqs_client.delete_message(queue_url: @queue_url, receipt_handle: msg.receipt_handle)
  end
end
