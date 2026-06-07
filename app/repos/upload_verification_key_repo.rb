# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UploadVerificationKeyRepo < PastaAtlas::DB::Repo
      def create_many(upload_id:, s3_keys:)
        rows = s3_keys.map {|key| {upload_id:, s3_key: key} }
        upload_verification_keys.dataset
          .insert_conflict(target: %i[upload_id s3_key])
          .multi_insert(rows)
      end

      def mark_verified_batch(upload_id:, results:)
        now = Time.now
        upload_verification_keys.transaction do
          results.each do |result|
            upload_verification_keys.dataset
              .where(upload_id:, s3_key: result[:s3_key])
              .update(verified_at: now, size_bytes: result[:size_bytes])
          end
        end
      end

      def count_verified(upload_id:)
        upload_verification_keys.dataset
          .where(upload_id:)
          .exclude(verified_at: nil)
          .count
      end
    end
  end
end
