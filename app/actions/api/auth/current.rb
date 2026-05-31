# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Auth
        class Current < PastaAtlas::Action
          include Deps[
            "repos.user_profile_repo",
            "settings"
          ]

          def handle(request, response)
            user_id = current_user_id(request)
            return json_response(response, {user: nil}) unless user_id

            user = user_repo.find_by_id(user_id)
            profile = user_profile_repo.find_by_user_id(user_id)
            avatar_url = profile.avatar_s3_key ? "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}" : nil

            json_response(response, {
              user: {
                name: user.name,
                display_name: profile.display_name || user.name,
                avatar_url:
              }
            })
          rescue ROM::TupleCountMismatchError
            json_response(response, {user: nil})
          end
        end
      end
    end
  end
end
