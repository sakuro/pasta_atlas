# frozen_string_literal: true

module PastaAtlas
  module Operations
    class CleanupGuestMaps < PastaAtlas::Operation
      include Deps[
        "repos.generation_repo",
        "repos.map_repo"
      ]

      def call
        deleted_generations = step delete_expired_generations
        deleted_maps = step delete_orphan_maps
        {deleted_generations:, deleted_maps:}
      end

      private def delete_expired_generations = Success(generation_repo.delete_expired)

      private def delete_orphan_maps = Success(map_repo.delete_guest_orphans)
    end
  end
end
