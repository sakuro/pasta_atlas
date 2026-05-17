# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class UpdateName < PastaAtlas::Operation
        include Deps["repos.map_repo", "repos.user_repo"]

        def call(ulid:, name:, current_user_id:)
          return Failure(:unauthorized) unless current_user_id

          user = step find_user(current_user_id)
          map = step find_map(ulid)
          step check_owner(map, user)
          step rename(map.id, name)
        end

        private def find_user(user_id)
          user = user_repo.find_by_id(user_id)
          user.name == "guest" ? Failure(:forbidden) : Success(user)
        end

        private def find_map(ulid)
          map = map_repo.find_by_ulid(ulid)
          map ? Success(map) : Failure(:not_found)
        end

        private def check_owner(map, user)
          map.user_id == user.id ? Success(map) : Failure(:forbidden)
        end

        private def rename(id, name)
          map_repo.update_name(id:, name:)
          Success(map_repo.find_by_id(id))
        end
      end
    end
  end
end
