# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Maps
      class Viewer < PastaAtlas::Action
        include Deps[
          "operations.user.find_by_id",
          "settings",
          show_map: "operations.maps.show"
        ]

        def handle(request, response)
          ulid = request.params[:ulid]
          case show_map.call(ulid:)
          in Success({map:, user:, profile:, updated_at:, thumbnail_url:})
            avatar_url = profile.avatar_s3_key ? "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}" : nil
            author_info = Values::UserInfo[name: user.name, display_name: profile.display_name || user.name, avatar_url:]
            viewer_id = current_user_id(request)
            viewer_name = viewer_id && find_by_id.call(user_id: viewer_id).value!.name
            response.render(
              view,
              ulid: map.ulid,
              display_name: map.display_name,
              author_info:,
              updated_at:,
              thumbnail_url:,
              viewer_name:
            )
          in Failure(Symbol => status)
            halt status
          end
        end
      end
    end
  end
end
