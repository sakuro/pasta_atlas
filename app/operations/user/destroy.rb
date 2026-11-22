# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      class Destroy < PastaAtlas::Operation
        include Deps[
          "repos.map_repo",
          "repos.user_repo",
          "settings",
          sqs_client: "sqs.client"
        ]

        def call(user:)
          s3_prefixes = map_s3_prefixes(user) + ["#{user.name}/avatar/"]
          # Queued before the user is deleted: no cleanup sweeps the prefixes of a user missing from
          # the database, so a message that cannot be queued must keep the user, and deleting again
          # retries. Objects removed for a user whose deletion then fails are no loss, as the user
          # asked for the deletion and repeats it.
          step schedule_s3_cleanup(s3_prefixes)
          user_repo.destroy(user.id)
          user
        end

        private def map_s3_prefixes(user)
          map_repo.find_all_by_user_id(user.id).map {|m| "#{user.name}/maps/#{m.mapshot_map_id}/" }
        end

        private def schedule_s3_cleanup(prefixes)
          prefixes.each do |prefix|
            sqs_client.send_message(queue_url: settings.sqs_s3_cleanup_queue_url, message_body: prefix)
          end
          Success()
        rescue Aws::SQS::Errors::ServiceError
          Failure(:bad_gateway)
        end
      end
    end
  end
end
