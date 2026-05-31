# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Users
        module Profile
          class Update < PastaAtlas::Action
            include Deps[
              "settings",
              load_profile: "operations.user.profile.load",
              update_profile: "operations.user.profile.update"
            ]

            params do
              required(:user_name).filled(:string)
              required(:display_name).filled(:string)
              optional(:avatar_s3_key).maybe(:string)
            end

            def handle(request, response)
              result = update_profile.call(
                user_id: current_user_id(request),
                user_name: request.params[:user_name],
                display_name: request.params[:display_name].to_s,
                avatar_s3_key: request.params[:avatar_s3_key].to_s
              )
              case result
              in Failure(:invalid, error)
                json_response(response, {error:}, status: 422)
              in Failure(Symbol => status)
                halt status
              in Success(user)
                profile_data = load_profile.call(user_id: user.id).value!
                json_response(response, {
                  display_name: profile_data[:display_name] || user.name,
                  avatar_url: profile_data[:avatar_url]
                })
              end
            end
          end
        end
      end
    end
  end
end
