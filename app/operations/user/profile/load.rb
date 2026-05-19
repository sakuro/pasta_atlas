# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Profile
        class Load < PastaAtlas::Operation
          include Deps["repos.user_profile_repo", "settings"]

          def call(user_id:)
            profile = user_profile_repo.find_by_user_id(user_id)
            avatar_url = profile.avatar_s3_key ? "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}" : nil
            {display_name: profile.display_name, avatar_url:}
          end
        end
      end
    end
  end
end
