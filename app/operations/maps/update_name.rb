# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class UpdateName < PastaAtlas::Operation
        include Deps["repos.map_repo", "repos.user_repo"]

        MAP_NAME_MAX_GRAPHEME_CLUSTERS = 30
        private_constant :MAP_NAME_MAX_GRAPHEME_CLUSTERS

        def call(ulid:, name:, current_user_id:)
          user = step find_user(current_user_id)
          map = step find_map(ulid)
          step check_owner(map, user)
          step validate_name(name)
          rename(map.id, name)
        end

        private def find_user(user_id)
          user = user_repo.find_by_id(user_id)
          user.can_rename_map? ? Success(user) : Failure(:forbidden)
        end

        private def find_map(ulid)
          map = map_repo.find_by_ulid(ulid)
          map ? Success(map) : Failure(:not_found)
        end

        private def check_owner(map, user)
          map.owned_by?(user) ? Success(map) : Failure(:forbidden)
        end

        private def validate_name(name)
          return Failure([:invalid, "error-map-name-too-long"]) if grapheme_clusters_exceed?(name, MAP_NAME_MAX_GRAPHEME_CLUSTERS)
          return Failure([:invalid, "error-map-name-invalid-chars"]) if name.match?(DISALLOWED_CHARS)

          Success()
        end

        private def rename(id, name)
          map_repo.update_name(id:, name:)
          map_repo.find_by_id(id)
        end
      end
    end
  end
end
