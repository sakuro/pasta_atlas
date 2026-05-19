# frozen_string_literal: true

module PastaAtlas
  module Operations
    class CleanupGuestMaps < PastaAtlas::Operation
      include Deps[
        "repos.generation_repo",
        "repos.map_repo"
      ]

      def call
        deleted_generations = generation_repo.delete_expired
        deleted_maps = map_repo.delete_guest_orphans
        {deleted_generations:, deleted_maps:}
      end
    end
  end
end
