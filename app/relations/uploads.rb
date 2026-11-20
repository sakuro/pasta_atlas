# frozen_string_literal: true

module PastaAtlas
  module Relations
    class Uploads < PastaAtlas::DB::Relation
      schema :uploads, infer: true do
        associations do
          belongs_to :generation
          has_one :current_upload_status
          has_many :upload_events
          has_many :upload_verification_keys
        end
      end

      # The generation and the owner of every upload that is not complete and has had no activity
      # since +before+. The last activity is the creation of the upload or its latest verified
      # key, whichever is newer. The joins span several tables, so the rows are plain hashes.
      def stale_incomplete_rows(before)
        db = dataset.db
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
    end
  end
end
