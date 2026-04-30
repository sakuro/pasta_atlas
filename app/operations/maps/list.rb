# frozen_string_literal: true

module PastaAtlas
  module Operations
    module Maps
      class List < PastaAtlas::Operation
        include Deps["repos.map_repo", "repos.user_repo"]

        PER_PAGE = 20
        private_constant :PER_PAGE

        def call(page: 1)
          maps = map_repo.list_with_complete_generation(page:, per_page: PER_PAGE)
          total = map_repo.count_with_complete_generation

          user_ids = maps.map(&:user_id).uniq
          users_by_id = user_repo.find_by_ids(user_ids).to_h {|u| [u.id, u] }

          {maps:, users_by_id:, page:, per_page: PER_PAGE, total:}
        end
      end
    end
  end
end
