# frozen_string_literal: true

namespace :sqs do
  desc "Poll SQS S3 cleanup queue and process messages (local dev)"
  task worker: :environment do
    sqs_client = Hanami.app["sqs.client"]
    queue_url = Hanami.app["settings"].sqs_s3_cleanup_queue_url

    loop do
      resp = sqs_client.receive_message(
        queue_url:,
        max_number_of_messages: 1,
        wait_time_seconds: 20
      )
      resp.messages.each do |msg|
        result = Hanami.app["operations.maps.delete"].call(s3_prefix: msg.body)
        if result.success?
          sqs_client.delete_message(queue_url:, receipt_handle: msg.receipt_handle)
          puts "Deleted S3 objects under #{msg.body}"
        else
          warn "Failed to delete S3 objects under #{msg.body}: #{result.failure}"
        end
      end
    end
  end
end
