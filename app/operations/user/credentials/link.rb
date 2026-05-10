# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Credentials
        class Link < PastaAtlas::Operation
          include Deps["repos.credential_repo"]

          def call(user_id:, provider:, uid:)
            step check_not_taken(provider, uid, user_id)
            credential_repo.create(user_id:, provider:, uid:)
          end

          private def check_not_taken(provider, uid, user_id)
            existing = credential_repo.find_by_provider_and_uid(provider, uid)
            return Failure(:conflict) if existing && existing.user_id != user_id
            return Failure(:already_linked) if existing

            Success()
          end
        end
      end
    end
  end
end
