# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      class FindById < PastaAtlas::Operation
        include Deps["repos.user_repo"]

        def call(user_id:)
          step find(user_id)
        end

        private def find(user_id)
          user = user_repo.find_by_id(user_id)
          user ? Success(user) : Failure(:not_found)
        end
      end
    end
  end
end
