# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class RequestDeletion < PastaAtlas::Operation
        include Deps["repos.map_repo", "repos.user_repo", "settings", sqs_client: "sqs.client"]

        def call(ulid:, current_user_id:)
          user = step find_user(current_user_id)
          map = step find_map(ulid)
          step check_owner(map, user)
          request_deletion(map)
          map
        end

        private def find_user(user_id)
          return Failure(:unauthorized) unless user_id

          user = user_repo.find_by_id(user_id)
          user.guest? ? Failure(:forbidden) : Success(user)
        end

        private def find_map(ulid)
          map = map_repo.find_by_ulid(ulid)
          map ? Success(map) : Failure(:not_found)
        end

        private def check_owner(map, user)
          map.owned_by?(user) ? Success(map) : Failure(:forbidden)
        end

        private def request_deletion(map)
          sqs_client.send_message(
            queue_url: settings.sqs_map_deletion_queue_url,
            message_body: map.ulid
          )
        end
      end
    end
  end
end
