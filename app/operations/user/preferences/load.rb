# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Preferences
        class Load < PastaAtlas::Operation
          include Deps["repos.user_preference_repo"]

          def call(user_id:, viewer_id:)
            step same_user?(user_id, viewer_id)
            user_preference_repo.find_by_user_id(user_id)
          end

          private def same_user?(user_id, viewer_id) = viewer_id == user_id ? Success(nil) : Failure(:not_viewable)
        end
      end
    end
  end
end
