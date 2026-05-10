# frozen_string_literal: true

module PastaAtlas
  module Repos
    class CredentialRepo < PastaAtlas::DB::Repo
      def find_by_provider_and_uid(provider, uid) = credentials.where(provider:, uid:).one
      def find_by_user_id(user_id) = credentials.where(user_id:).to_a
      def count_by_user_id(user_id) = credentials.where(user_id:).count
      def create(user_id:, provider:, uid:) = credentials.command(:create).call(user_id:, provider:, uid:, data: {})
      def delete_by_user_id_and_provider(user_id, provider) = credentials.where(user_id:, provider:).delete
    end
  end
end
