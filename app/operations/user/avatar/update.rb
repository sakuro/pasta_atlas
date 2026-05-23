# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Avatar
        class Update < PastaAtlas::Operation
          include Deps[
            "repos.user_profile_repo",
            "settings",
            "operations.user.verify_ownership",
            sqs_client: "sqs.client"
          ]

          def call(user_id:, user_name:, s3_key:)
            user = step verify_ownership.call(user_id:, user_name:)
            step validate_s3_key(s3_key, user.id)
            old_s3_key = user_profile_repo.find_by_user_id(user.id).avatar_s3_key
            user_profile_repo.update_avatar(user.id, avatar_s3_key: s3_key)
            schedule_s3_cleanup(old_s3_key) if old_s3_key
            user
          end

          private def validate_s3_key(s3_key, user_id)
            s3_key.start_with?("avatars/#{user_id}/") ? Success(s3_key) : Failure(:unprocessable_entity)
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
