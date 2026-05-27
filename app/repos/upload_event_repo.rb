# frozen_string_literal: true

module PastaAtlas
  module Repos
    class UploadEventRepo < PastaAtlas::DB::Repo
      def create(attrs)
        upload_events.changeset(:create, attrs).commit
      end
    end
  end
end
