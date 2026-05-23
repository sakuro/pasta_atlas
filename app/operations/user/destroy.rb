# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      class Destroy < PastaAtlas::Operation
        include Deps[
          "operations.user.verify_ownership",
          "repos.map_repo",
          "repos.user_repo",
          "settings",
          sqs_client: "sqs.client"
        ]

        def call(user_id:, user_name:)
          user = step verify_ownership.call(user_id:, user_name:)
          s3_prefixes = map_s3_prefixes(user) + ["avatars/#{user.id}/"]
          user_repo.destroy(user.id)
          s3_prefixes.each {|prefix| schedule_s3_cleanup(prefix) }
          user
        end

        private def map_s3_prefixes(user)
          map_repo.find_all_by_user_id(user.id).map {|m| "#{user.name}/#{m.mapshot_map_id}/" }
        end

        private def schedule_s3_cleanup(prefix)
          sqs_client.send_message(
            queue_url: settings.sqs_s3_cleanup_queue_url,
            message_body: prefix
          )
        rescue Aws::SQS::Errors::ServiceError
          # Objects will be cleaned up by the periodic orphan cleanup job
        end
      end
    end
  end
end
