# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Uploads
      class UpdateStatus < PastaAtlas::Operation
        include Deps["repos.upload_repo"]

        def call(upload_ulid:, status:)
          upload = step find_upload(upload_ulid)
          update_upload(upload, status)
        end

        private def find_upload(ulid)
          upload = upload_repo.find_by_ulid(ulid)
          upload ? Success(upload) : Failure(:not_found)
        end

        private def update_upload(upload, status)
          attrs = {status:}
          attrs[:completed_at] = Time.now if status == "complete"
          upload_repo.update_status(id: upload.id, **attrs)
        end
      end
    end
  end
end
