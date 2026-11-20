# frozen_string_literal: true

require_relative "sqs_queue_worker"
require_relative "storage_calculation_processor"

class StorageCalculationQueueWorker < SqsQueueWorker
  def initialize(sqs_client:, settings:, stop:, wait_time_seconds:, processor: nil)
    super(sqs_client:, queue_url: settings.sqs_storage_calculation_queue_url, stop:, wait_time_seconds:)
    @processor = processor || StorageCalculationProcessor.new(
      operation: Hanami.app["operations.generations.calculate_storage"]
    )
  end

  private def handle(msg)
    return unless @processor.call(msg.body).success?

    @sqs_client.delete_message(queue_url: @queue_url, receipt_handle: msg.receipt_handle)
  end
end
