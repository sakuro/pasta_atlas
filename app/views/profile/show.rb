# frozen_string_literal: true

module PastaAtlas
  module Views
    module Profile
      class Show < Hanami::View
        expose :user_name, :display_name, :own_profile
      end
    end
  end
end
