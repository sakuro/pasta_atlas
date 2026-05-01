# frozen_string_literal: true

module PastaAtlas
  module Views
    module Profile
      class Edit < Hanami::View
        expose :display_name, :timezone, :timezone_identifiers, :error
      end
    end
  end
end
