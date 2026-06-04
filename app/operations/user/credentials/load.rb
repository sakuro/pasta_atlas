# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      module Credentials
        class Load < PastaAtlas::Operation
          include Deps["repos.credential_repo"]

          def call(user_id:)
            credential_repo.find_by_user_id(user_id).map(&:provider).sort!
          end
        end
      end
    end
  end
end
