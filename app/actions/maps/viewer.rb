# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Maps
      class Viewer < PastaAtlas::Action
        include Deps["repos.user_profile_repo", "settings", show_map: "operations.maps.show"]

        def handle(request, response)
          ulid = request.params[:ulid]
          case show_map.call(ulid:)
          in Success({map:, user:, generations:})
            profile = user_profile_repo.find_by_user_id(user.id)
            avatar_url = profile.avatar_s3_key ? "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}" : nil
            author_info = Values::UserInfo[name: user.name, display_name: profile.display_name || user.name, avatar_url:]
            updated_at = generations.map(&:created_at).max
            viewer_id = current_user_id(request)
            viewer = viewer_id ? user_repo.find_by_id(viewer_id) : nil
            viewer_name = viewer && !viewer.guest? ? viewer.name : nil
            response.render(
              view,
              ulid: map.ulid,
              display_name: map.display_name,
              author_info:,
              updated_at:,
              viewer_name:
            )
          in Failure(:not_found)
            halt 404
          end
        end
      end
    end
  end
end
