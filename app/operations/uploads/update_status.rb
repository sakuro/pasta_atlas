# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Uploads
      class UpdateStatus < PastaAtlas::Operation
        ALLOWED_STATUSES = %w[complete failed].freeze
        private_constant :ALLOWED_STATUSES

        include Deps[
          "repos.upload_event_repo",
          "repos.upload_repo"
        ]

        def call(upload_ulid:, status:)
          step validate_status(status)
          upload = step find_upload(upload_ulid)
          step append_event(upload, status)
          step find_upload(upload_ulid)
        end

        private def validate_status(status) = ALLOWED_STATUSES.include?(status) ? Success() : Failure(:bad_request)

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
