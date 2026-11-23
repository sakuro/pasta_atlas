# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      class VerifyOwnership < PastaAtlas::Operation
        def call(current_user:, user_name:)
          step check_ownership(current_user, user_name)
        end

        # A request without a session runs as the guest system user, so a name match alone would let
        # anyone act on the guest account (and so on every map uploaded without logging in).
        private def check_ownership(current_user, user_name)
          current_user.public_profile? && current_user.name == user_name ? Success(current_user) : Failure(:forbidden)
        end
      end
    end
  end
end
