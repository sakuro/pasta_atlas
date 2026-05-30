# frozen_string_literal: true

module PastaAtlas
  module Actions
    module User
      module Profile
        class Update < PastaAtlas::Action
          include Deps[update_profile: "operations.user.profile.update"]

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
              response.flash[:error] = error
              response.redirect_to "#{routes.path(:user, user_name: request.params[:user_name])}#tab-profile"
            in Failure(Symbol => status)
              halt status
            in Success(user)
              response.redirect_to "#{routes.path(:user, user_name: user.name)}#tab-profile"
            end
          end
        end
      end
    end
  end
end
