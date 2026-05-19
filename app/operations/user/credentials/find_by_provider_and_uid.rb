# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Credentials
        class FindByProviderAndUid < PastaAtlas::Operation
          include Deps["repos.credential_repo"]

          def call(provider:, uid:)
            step find(provider, uid)
          end

          private def find(provider, uid)
            credential = credential_repo.find_by_provider_and_uid(provider, uid)
            credential ? Success(credential) : Failure(:not_found)
          end
        end
      end
    end
  end
end
