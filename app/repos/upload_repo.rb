# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UploadRepo < PastaAtlas::DB::Repo
      def find_by_ulid(ulid) = uploads.where(ulid:).combine(:current_upload_status).one

      def create(attrs)
        uploads.changeset(:create, attrs).commit
      end

      def update_verification(id:, verification_status:, verified_at: nil)
        uploads.dataset.where(id:).update(verification_status:, verified_at:)
      end

      def accumulate_verified_bytes(id:, bytes:)
        uploads.dataset.where(id:).update(
          verified_bytes: Sequel.lit("verified_bytes + ?", bytes)
        )
      end
    end
  end
end
