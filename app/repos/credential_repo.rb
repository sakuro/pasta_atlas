# frozen_string_literal: true

module PastaAtlas
  module Repos
    class CredentialRepo < PastaAtlas::DB::Repo
      def find_by_provider_and_uid(provider, uid) = credentials.where(provider:, uid:).one
    end
  end
end
