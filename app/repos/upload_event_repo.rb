# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UploadEventRepo < PastaAtlas::DB::Repo
      def create(upload_id:, event_type:, occurred_at: nil)
        # Passing nil for occurred_at would override the column default (now()) with NULL.
        upload_events.command(:create).call({upload_id:, event_type:, occurred_at:}.compact)
      end
    end
  end
end
