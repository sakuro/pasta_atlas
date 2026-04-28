# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UploadRepo < PastaAtlas::DB::Repo
      def find_by_ulid(ulid) = uploads.where(ulid:).one

      def create(attrs)
        uploads.changeset(:create, attrs).commit
      end

      def update_status(id:, **attrs)
        uploads.where(id:).changeset(:update, attrs).commit
      end
    end
  end
end
