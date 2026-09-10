# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Uploads
        module PresignedPosts
          class Create < PastaAtlas::Action
            include Deps["operations.uploads.issue_presigned_posts"]

            contract do
              params do
                required(:ulid).filled(:string)
                required(:filenames).array(:string)
              end

              rule(:filenames) do
                if values[:filenames].length > 200
                  key.failure("too many filenames")
                else
                  # file_prefix = "s" .. surface.index .. "zoom_":
                  # https://github.com/Palats/mapshot/blob/ddad172f187d08e56df720efe2fe0bddfb65e347/mod/control.lua#L295
                  # path = data_prefix .. "tile_" .. tile_x .. "_" .. tile_y .. ".jpg":
                  # https://github.com/Palats/mapshot/blob/ddad172f187d08e56df720efe2fe0bddfb65e347/mod/control.lua#L338
                  pattern = %r{\As\d+zoom_\d+/tile_-?\d+_-?\d+\.jpg\z}
                  key.failure("contains invalid filenames") unless values[:filenames].all? {|f| pattern.match?(f) }
                end
              end
            end

            def handle(request, response)
              halt :bad_request unless request.params.valid?

              result = issue_presigned_posts.call(
                upload_ulid: request.params[:ulid],
                filenames: request.params[:filenames],
                user_id: current_user_id(request)
              )

              case result
              in Success(posts)
                json_response(response, {presigned_posts: posts})
              in Failure(Symbol => status)
                halt status
              end
            end
          end
        end
      end
    end
  end
end
