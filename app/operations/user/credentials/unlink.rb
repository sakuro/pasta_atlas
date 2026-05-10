# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Credentials
        class Unlink < PastaAtlas::Operation
          include Deps["repos.credential_repo"]

          def call(user_id:, provider:)
            step check_not_last(user_id)
            credential_repo.delete_by_user_id_and_provider(user_id, provider)
          end

          private def check_not_last(user_id)
            credential_repo.count_by_user_id(user_id) <= 1 ? Failure(:last_credential) : Success()
          end
        end
      end
    end
  end
end
