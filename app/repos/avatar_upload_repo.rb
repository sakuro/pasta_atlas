# frozen_string_literal: true

module PastaAtlas
  module Repos
    # The avatar keys issued to users, so that only a key issued to the user, still valid and not
    # applied yet can become their avatar.
    class AvatarUploadRepo < PastaAtlas::DB::Repo
      def create(user_id:, s3_key:, content_type:, expires_at:)
        avatar_uploads.command(:create).call(user_id:, s3_key:, content_type:, expires_at:)
      end

      def count_pending(user_id:, now:) = pending(user_id, now).count

      def find_pending(user_id:, s3_key:, now:) = pending(user_id, now).where(s3_key:).one

      # Returns how many uploads this call consumed: 0 when it was already applied, so that concurrent
      # requests cannot both apply it.
      def consume(id:, now:) = avatar_uploads.dataset.where(id:, consumed_at: nil).update(consumed_at: now)

      def delete_expired_before(time) = avatar_uploads.dataset.where(Sequel[:expires_at] < time).delete

      private def pending(user_id, now) = avatar_uploads.where(user_id:, consumed_at: nil).where(Sequel[:expires_at] > now)
    end
  end
end
