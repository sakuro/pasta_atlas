# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Users
        module Maps
          class Index < PastaAtlas::Action
            include Deps[
              "operations.user.find_by_name",
              list_recent_maps: "operations.maps.list_recent_by_user",
              load_profile: "operations.user.profile.load"
            ]

            def handle(request, response)
              result = find_by_name.call(user_name: request.params[:user_name])
              case result
              in Failure(Symbol => status)
                halt status
              in Success(user)
                halt :not_found if user.guest?

                profile_data = load_profile.call(user_id: user.id).value!
                user_info = Values::UserInfo[
                  name: user.name,
                  display_name: profile_data[:display_name] || user.name,
                  avatar_url: profile_data[:avatar_url]
                ]
                map_infos = list_recent_maps.call(user_id: user.id, user_info:).value!
                json_response(response, {
                  maps: map_infos.map {|m|
                    {
                      ulid: m.ulid,
                      display_name: m.display_name,
                      user_name: m.user_info.name,
                      author_display_name: m.user_info.display_name,
                      author_avatar_url: m.user_info.avatar_url,
                      thumbnail_url: m.thumbnail_url,
                      metadata_url: m.metadata_url,
                      updated_at: m.updated_at&.iso8601
                    }
                  }
                })
              end
            end
          end
        end
      end
    end
  end
end
