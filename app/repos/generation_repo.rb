# frozen_string_literal: true

module PastaAtlas
  module Repos
    class GenerationRepo < PastaAtlas::DB::Repo
      NOT_EXPIRED = Sequel.lit("(expires_at IS NULL OR expires_at > NOW())")
      private_constant :NOT_EXPIRED

      def find_by_id(id) = generations.where(id:).one!

      def find_latest_complete_by_map_ids(map_ids)
        generations.where(map_id: map_ids)
          .where(NOT_EXPIRED)
          .combine(upload: :current_upload_status)
          .to_a
          .select {|g| g.upload&.status == "complete" }
          .group_by(&:map_id)
          .transform_values {|gens| gens.max_by(&:tick) }
      end

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
          .where(NOT_EXPIRED)
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

      def all_expired_for_map?(map_id:)
        dataset = generations.dataset.where(map_id:)
        dataset.any? && dataset.where(NOT_EXPIRED).none?
      end

      def delete_expired
        generations.dataset.where(Sequel.lit("expires_at IS NOT NULL AND expires_at <= NOW()")).delete
      end
    end
  end
end
