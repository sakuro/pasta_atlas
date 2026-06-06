# frozen_string_literal: true

require_relative "sqs_queue_worker"

class StorageCalculationQueueWorker < SqsQueueWorker
  def initialize(sqs_client:, settings:, stop:, wait_time_seconds:)
    super(sqs_client:, queue_url: settings.sqs_storage_calculation_queue_url, stop:, wait_time_seconds:)
  end

  private def handle(msg)
    generation_id = Integer(msg.body)
    result = Hanami.app["operations.generations.calculate_storage"].call(generation_id:)
    if result.success?
      @sqs_client.delete_message(queue_url: @queue_url, receipt_handle: msg.receipt_handle)
      puts "Calculated storage for generation #{generation_id}: #{result.value!} bytes"
    else
      warn "Failed to calculate storage for generation #{generation_id}: #{result.failure}"
    end
  end
end
