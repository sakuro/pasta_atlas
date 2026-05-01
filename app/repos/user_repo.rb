# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UserRepo < PastaAtlas::DB::Repo
      def find_by_id(id) = users.where(id:).one!
      def find_by_ids(ids) = users.where(id: ids).to_a
      def find_by_name(name) = users.where(name:).one
      def create(name:) = users.command(:create).call(name:)
    end
  end
end
