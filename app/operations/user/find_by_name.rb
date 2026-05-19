# frozen_string_literal: true

module PastaAtlas
  module Operations
    module User
      class FindByName < PastaAtlas::Operation
        include Deps["repos.user_repo"]

        def call(user_name:)
          step find(user_name)
        end

        private def find(user_name)
          user = user_repo.find_by_name(user_name)
          user ? Success(user) : Failure(:not_found)
        end
      end
    end
  end
end
