# frozen_string_literal: true

require "ulid"

module PastaAtlas
  module Actions
    module User
      module AvatarPresignedUrl
        class Create < PastaAtlas::Action
          include Deps["settings", s3_client: "s3.client"]

          ALLOWED_CONTENT_TYPES = {
            "image/jpeg" => "jpg",
            "image/png" => "png",
            "image/webp" => "webp"
          }.freeze
          private_constant :ALLOWED_CONTENT_TYPES

          def handle(request, response)
            user_id = current_user_id(request)
            halt 403 unless user_id

            content_type = request.params[:content_type].to_s
            ext = ALLOWED_CONTENT_TYPES[content_type]
            halt 422 unless ext

            key = "avatars/#{user_id}/#{ULID.generate}.#{ext}"
            presigner = Aws::S3::Presigner.new(client: s3_client)
            presigned_url = presigner.presigned_url(
              :put_object,
              bucket: settings.s3_bucket,
              key:,
              expires_in: settings.presigned_url_expiry,
              content_type:
            )

            json_response(response, {presigned_url:, s3_key: key})
          end
        end
      end
    end
  end
end
