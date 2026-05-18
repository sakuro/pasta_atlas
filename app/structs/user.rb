# frozen_string_literal: true

module PastaAtlas
  module Structs
    class User < PastaAtlas::DB::Struct
      def guest? = name == "guest"
    end
  end
end
