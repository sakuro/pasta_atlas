# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Uploads
      class UpdateStatus < PastaAtlas::Operation
        include Deps[
          "repos.upload_event_repo",
          "repos.upload_repo"
        ]

        def call(upload_ulid:, status:)
          upload = step find_upload(upload_ulid)
          step append_event(upload, status)
          step find_upload(upload_ulid)
        end

        private def find_upload(ulid)
          upload = upload_repo.find_by_ulid(ulid)
          upload ? Success(upload) : Failure(:not_found)
        end

        private def append_event(upload, status)
          upload_event_repo.create(upload_id: upload.id, event_type: status)
          Success()
        end
      end
    end
  end
end
