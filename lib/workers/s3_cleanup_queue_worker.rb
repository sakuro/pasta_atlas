# frozen_string_literal: true

require_relative "sqs_queue_worker"

class S3CleanupQueueWorker < SqsQueueWorker
  def initialize(sqs_client:, settings:, stop:, wait_time_seconds:)
    super(sqs_client:, queue_url: settings.sqs_s3_cleanup_queue_url, stop:, wait_time_seconds:)
  end

  private def handle(msg)
    result = Hanami.app["operations.delete_s3_prefix"].call(s3_prefix: msg.body)
    if result.success?
      @sqs_client.delete_message(queue_url: @queue_url, receipt_handle: msg.receipt_handle)
      puts "Deleted S3 objects under #{msg.body}"
    else
      warn "Failed to delete S3 objects under #{msg.body}: #{result.failure}"
    end
  end
end
