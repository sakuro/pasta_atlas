# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UploadRepo < PastaAtlas::DB::Repo
      def find_by_ulid(ulid) = root.where(ulid:).one

      def create(attrs)
        root.changeset(:create, attrs).commit
      end

      def update_status(id:, **attrs)
        root.where(id:).changeset(:update, attrs).commit
      end
    end
  end
end
