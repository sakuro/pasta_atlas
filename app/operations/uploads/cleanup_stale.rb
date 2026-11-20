# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Uploads
      # Deletes generations whose upload was started and then abandoned, together with their
      # S3 objects. Interrupted uploads are resumed by selecting the same folder again, so
      # only uploads without activity for settings.stale_upload_days are touched.
      class CleanupStale < PastaAtlas::Operation
        include Deps[
          "repos.generation_repo",
          "repos.upload_repo",
          "settings",
          sqs_client: "sqs.client"
        ]

        SECONDS_PER_DAY = 24 * 60 * 60
        private_constant :SECONDS_PER_DAY

        def call(now: Time.now)
          stale = upload_repo.find_stale_incomplete(before: now - (settings.stale_upload_days * SECONDS_PER_DAY))
          deleted = stale.count {|row| delete_generation(row) }

          {found: stale.size, deleted:, failed: stale.size - deleted}
        end

        # The prefix is queued before the records are deleted, as VerifyBatch does: if queuing
        # fails the records stay and the next run tries again.
        private def delete_generation(row)
          prefix = "#{row.user_name}/maps/#{row.mapshot_map_id}/#{row.mapshot_unique_id}/"
          sqs_client.send_message(queue_url: settings.sqs_s3_cleanup_queue_url, message_body: prefix)
          generation_repo.delete_by_id(row.generation_id)
          true
        rescue Aws::SQS::Errors::ServiceError
          false
        end
      end
    end
  end
end
