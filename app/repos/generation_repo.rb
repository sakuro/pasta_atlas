# frozen_string_literal: true

module PastaAtlas
  module Repos
    class GenerationRepo < PastaAtlas::DB::Repo
      def find_by_id(id) = generations.where(id:).one

      def find_complete_by_map_id(map_id)
        generations.where(map_id:)
          .combine(:upload)
          .to_a
          .select {|g| g.upload&.status == "complete" }
          .sort_by {|g| -g.tick }
      end

      def find_with_upload(map_id:, mapshot_unique_id:)
        generations.by_map_and_unique_id(map_id, mapshot_unique_id).combine(:upload).one
      end

      def create(attrs)
        generations.changeset(:create, attrs).commit
      end

      # Returns the Sequel::Database connection for transaction management
      def db = generations.dataset.db
    end
  end
end
