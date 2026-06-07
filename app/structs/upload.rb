# frozen_string_literal: true

module PastaAtlas
  module Structs
    class Upload < PastaAtlas::DB::Struct
      def status = current_upload_status.status

      def pending? = status == "pending"

      def complete? = status == "complete"

      def completed_at = complete? ? current_upload_status.occurred_at : nil

      def verification_pending? = verification_status == "pending"

      def verification_passed? = verification_status == "passed"

      def verification_failed? = verification_status == "failed"
    end
  end
end
