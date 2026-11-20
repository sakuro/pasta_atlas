# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UserRepo < PastaAtlas::DB::Repo
      def find_by_id(id) = users.where(id:).one
      def fetch_by_id(id) = users.where(id:).one!
      def find_by_ids(ids) = users.where(id: ids).to_a
      def find_by_name(name) = users.where(name:).one
      def create(name:) = users.command(:create).call(name:)
      def destroy(id) = users.where(id:).command(:delete).call

      # INSERT ... ON CONFLICT cannot be written with a ROM command.
      def find_or_create_by_name(name:)
        users.dataset.insert_conflict(target: :name).insert(name:)
        users.where(name:).one!
      end
    end
  end
end
