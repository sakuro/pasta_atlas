# frozen_string_literal: true

module PastaAtlas
  module Repos
    class GenerationRepo < PastaAtlas::DB::Repo
      def find_by_id(id) = root.where(id:).one

      def find_complete_by_map_id(map_id)
        root.where(map_id:)
          .combine(:upload)
          .to_a
          .select {|g| g.upload&.status == "complete" }
          .sort_by {|g| -g.tick }
      end

      def find_with_upload(map_id:, mapshot_unique_id:)
        root.by_map_and_unique_id(map_id, mapshot_unique_id).combine(:upload).one
      end

      def create(attrs)
        root.changeset(:create, attrs).commit
      end

      # Returns the Sequel::Database connection for transaction management
      def db = root.dataset.db
    end
  end
end
