# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UploadRepo < PastaAtlas::DB::Repo
      def find_by_ulid(ulid) = uploads.where(ulid:).combine(:current_upload_status).one

      def create(attrs)
        uploads.changeset(:create, attrs).commit
      end

      def find_stale_incomplete(before:)
        uploads.stale_incomplete_rows(before).map {|row| PastaAtlas::Values::StaleUpload.new(**row) }
      end

      def update_verification(id:, verification_status:, verified_at: nil)
        uploads.where(id:).command(:update).call(verification_status:, verified_at:)
      end

      # An atomic increment (`verified_bytes + n`) cannot be written with a ROM command.
      def accumulate_verified_bytes(id:, bytes:)
        uploads.dataset.where(id:).update(
          verified_bytes: Sequel.lit("verified_bytes + ?", bytes)
        )
      end
    end
  end
end
