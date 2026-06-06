# frozen_string_literal: true

module PastaAtlas
  module Structs
    class User < PastaAtlas::DB::Struct
      def guest? = name == "guest"
      def compilatron? = name == "compilatron"

      # Whether this user has a publicly accessible profile and map list.
      # System users are excluded from public visibility.
      def has_public_profile? = !guest? && !compilatron?

      def can_rename_map? = !guest?
      def can_delete_map? = !guest?
      def uploads_expire? = guest?
    end
  end
end
