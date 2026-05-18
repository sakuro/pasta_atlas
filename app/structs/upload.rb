# frozen_string_literal: true

module PastaAtlas
  module Structs
    class Upload < PastaAtlas::DB::Struct
      def pending? = status == "pending"

      def complete? = status == "complete"
    end
  end
end
