# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UploadRepo < PastaAtlas::DB::Repo
      def find_by_ulid(ulid) = uploads.where(ulid:).combine(:current_upload_status).one

      def create(attrs)
        uploads.changeset(:create, attrs).commit
      end

      # Uploads that are not complete and have seen no activity since +before+. The last
      # activity is the creation of the upload or its latest verified key, whichever is newer.
      def find_stale_incomplete(before:)
        db = uploads.dataset.db
        last_verified_at = db[:upload_verification_keys]
          .where(upload_id: Sequel[:uploads][:id])
          .select(Sequel.function(:max, :verified_at))
        last_activity = Sequel.function(
          :greatest,
          Sequel[:uploads][:created_at],
          Sequel.function(:coalesce, last_verified_at, Sequel[:uploads][:created_at])
        )

        db[:uploads]
          .join(:generations, id: :generation_id)
          .join(:maps, id: Sequel[:generations][:map_id])
          .join(:users, id: Sequel[:maps][:user_id])
          .left_join(:current_upload_statuses, upload_id: Sequel[:uploads][:id])
          .where(Sequel.|({Sequel[:current_upload_statuses][:status] => nil}, Sequel.~(Sequel[:current_upload_statuses][:status] => "complete")))
          .where(last_activity < before)
          .select(
            Sequel[:generations][:id].as(:generation_id),
            Sequel[:users][:name].as(:user_name),
            Sequel[:maps][:mapshot_map_id],
            Sequel[:generations][:mapshot_unique_id]
          )
          .all
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
