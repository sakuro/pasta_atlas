# frozen_string_literal: true

module PastaAtlas
  module Repos
    class GenerationRepo < PastaAtlas::DB::Repo
      def fetch_by_id(id) = generations.where(id:).one!

      def find_latest_complete_by_map_ids(map_ids)
        generations.where(map_id: map_ids)
          .combine(upload: :current_upload_status)
          .to_a
          .select {|g| g.upload&.status == "complete" }
          .group_by(&:map_id)
          .transform_values {|gens| gens.max_by(&:tick) }
      end

      # An aggregate: the result is a lookup of map id to time, not records.
      def find_max_created_at_by_map_ids(map_ids)
        return {} if map_ids.empty?

        generations.dataset
          .where(map_id: map_ids)
          .unordered
          .group(:map_id)
          .select(:map_id, Sequel.function(:max, :created_at).as(:max_created_at))
          .to_h {|row| [row[:map_id], row[:max_created_at]] }
      end

      def find_complete_by_map_id(map_id)
        generations.where(map_id:)
          .combine(upload: :current_upload_status)
          .to_a
          .select {|g| g.upload&.status == "complete" }
          .sort_by {|g| -g.tick }
      end

      def find_with_upload(map_id:, mapshot_unique_id:)
        generations.by_map_and_unique_id(map_id, mapshot_unique_id)
          .combine(upload: :current_upload_status)
          .one
      end

      def create(attrs)
        generations.changeset(:create, attrs).commit
      end

      def update_storage_bytes(id:, storage_bytes:)
        generations.where(id:).command(:update).call(storage_bytes:)
      end

      def delete_by_id(id) = generations.where(id:).command(:delete).call
    end
  end
end
