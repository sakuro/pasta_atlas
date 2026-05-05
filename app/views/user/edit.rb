# frozen_string_literal: true

module PastaAtlas
  module Views
    module User
      class Edit < Hanami::View
        expose :display_name, :timezone, :timezone_identifiers, :locale, :error, :avatar_url
      end
    end
  end
end
