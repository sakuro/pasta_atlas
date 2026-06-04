# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      class VerifyOwnership < PastaAtlas::Operation
        def call(current_user:, user_name:)
          current_user.name == user_name ? Success(current_user) : Failure(:forbidden)
        end
      end
    end
  end
end
