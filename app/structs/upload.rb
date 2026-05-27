# frozen_string_literal: true

module PastaAtlas
  module Structs
    class Upload < PastaAtlas::DB::Struct
      def status = current_upload_status.status

      def pending? = status == "pending"

      def complete? = status == "complete"

      def completed_at = complete? ? current_upload_status.occurred_at : nil
    end
  end
end
