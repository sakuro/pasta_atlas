# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UploadRepo < PastaAtlas::DB::Repo
      def find_by_ulid(ulid) = uploads.where(ulid:).combine(:current_upload_status).one

      def create(attrs)
        uploads.changeset(:create, attrs).commit
      end
    end
  end
end
