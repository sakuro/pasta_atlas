# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class UpdateName < PastaAtlas::Operation
        include Deps["repos.map_repo", "repos.user_repo"]

        MAP_NAME_MAX_GRAPHEME_CLUSTERS = 30
        private_constant :MAP_NAME_MAX_GRAPHEME_CLUSTERS

        def call(ulid:, display_name:, current_user_id:)
          user = step find_user(current_user_id)
          map = step find_map(ulid)
          step check_owner(map, user)
          step validate_display_name(display_name)
          rename(map.id, display_name)
        end

        private def find_user(user_id)
          user = user_repo.find_by_id!(user_id)
          user.can_rename_map? ? Success(user) : Failure(:forbidden)
        end

        private def find_map(ulid)
          map = map_repo.find_by_ulid(ulid)
          map ? Success(map) : Failure(:not_found)
        end

        private def check_owner(map, user)
          map.owned_by?(user) ? Success(map) : Failure(:forbidden)
        end

        private def validate_display_name(display_name)
          return Failure([:invalid, "error-map-name-blank"]) if display_name.empty?
          return Failure([:invalid, "error-map-name-too-long"]) if grapheme_clusters_exceed?(display_name, MAP_NAME_MAX_GRAPHEME_CLUSTERS)
          return Failure([:invalid, "error-map-name-invalid-chars"]) if display_name.match?(DISALLOWED_CHARS)

          Success()
        end

        private def rename(id, display_name)
          map_repo.update_display_name(id:, display_name:)
          map_repo.find_by_id!(id)
        end
      end
    end
  end
end
