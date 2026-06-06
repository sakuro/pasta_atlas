# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Users
        class Show < PastaAtlas::Action
          include Deps[
            "operations.user.find_by_name",
            load_profile: "operations.user.profile.load"
          ]

          def handle(request, response)
            result = find_by_name.call(user_name: request.params[:name])
            case result
            in Failure(Symbol => status)
              halt status
            in Success(user)
              halt :forbidden unless user.has_public_profile?

              profile_data = load_profile.call(user_id: user.id).value!
              json_response(response, {
                user: {
                  name: user.name,
                  display_name: profile_data[:display_name] || user.name,
                  avatar_url: profile_data[:avatar_url]
                }
              })
            end
          end
        end
      end
    end
  end
end
