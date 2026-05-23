# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Avatar
        class Destroy < PastaAtlas::Operation
          include Deps[
            "repos.user_profile_repo",
            "settings",
            "operations.user.verify_ownership",
            sqs_client: "sqs.client"
          ]

          def call(user_id:, user_name:)
            user = step verify_ownership.call(user_id:, user_name:)
            old_s3_key = user_profile_repo.find_by_user_id(user.id).avatar_s3_key
            user_profile_repo.clear_avatar(user.id)
            schedule_s3_cleanup(old_s3_key) if old_s3_key
            user
          end

          private def schedule_s3_cleanup(s3_key)
            sqs_client.send_message(
              queue_url: settings.sqs_s3_cleanup_queue_url,
              message_body: s3_key
            )
          rescue Aws::SQS::Errors::ServiceError
            # Objects will be cleaned up by the periodic orphan cleanup job
          end
        end
      end
    end
  end
end
