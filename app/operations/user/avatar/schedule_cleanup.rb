# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Avatar
        class ScheduleCleanup < PastaAtlas::Operation
          include Deps["settings", sqs_client: "sqs.client"]

          # Callers have already switched the avatar by the time they call this, so they treat a
          # failure as best effort: the unreferenced object stays in S3 until
          # CleanupOrphanedAvatars removes it.
          def call(s3_key:)
            step enqueue(s3_key)
          end

          private def enqueue(s3_key)
            sqs_client.send_message(queue_url: settings.sqs_s3_cleanup_queue_url, message_body: s3_key)
            Success()
          rescue Aws::SQS::Errors::ServiceError
            Failure(:enqueue_failed)
          end
        end
      end
    end
  end
end
