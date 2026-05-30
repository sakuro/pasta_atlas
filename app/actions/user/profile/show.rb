# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      module Profile
        class Show < PastaAtlas::Action
          include Deps[
            "operations.user.verify_ownership",
            load_profile: "operations.user.profile.load"
          ]

          def handle(request, response)
            result = verify_ownership.call(
              user_id: current_user_id(request),
              user_name: request.params[:user_name]
            )
            case result
            in Failure(Symbol => status)
              halt status
            in Success(user)
              profile_data = load_profile.call(user_id: user.id).value!
              json_response(response, {
                user_name: user.name,
                display_name: profile_data[:display_name],
                avatar_url: profile_data[:avatar_url]
              })
            end
          end
        end
      end
    end
  end
end
