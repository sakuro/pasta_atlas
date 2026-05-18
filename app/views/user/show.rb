# frozen_string_literal: true

module PastaAtlas
  module Views
    module User
      class Show < Hanami::View
        expose :user_name, :display_name, :own_profile, :preference, :connected_providers, :avatar_url, :recent_map_infos
      end
    end
  end
end
