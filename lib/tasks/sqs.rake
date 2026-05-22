# frozen_string_literal: true

namespace :sqs do
  desc "Poll SQS map deletion queue and process messages (local dev)"
  task worker: :environment do
    sqs_client = Hanami.app["sqs.client"]
    queue_url = Hanami.app["settings"].sqs_map_deletion_queue_url

    loop do
      resp = sqs_client.receive_message(
        queue_url:,
        max_number_of_messages: 1,
        wait_time_seconds: 20
      )
      resp.messages.each do |msg|
        result = Hanami.app["operations.maps.delete"].call(ulid: msg.body)
        if result.success? || result.failure == :not_found
          sqs_client.delete_message(queue_url:, receipt_handle: msg.receipt_handle)
          puts "Deleted map #{msg.body}"
        else
          warn "Failed to delete map #{msg.body}: #{result.failure}"
        end
      end
    end
  end
end
