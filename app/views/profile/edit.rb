# frozen_string_literal: true

module PastaAtlas
  module Views
    module Profile
      class Edit < Hanami::View
        expose :display_name, :timezone, :timezone_identifiers, :error, :avatar_url
      end
    end
  end
end
