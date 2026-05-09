# frozen_string_literal: true

module PastaAtlas
  module Views
    module User
      class Edit < Hanami::View
        expose :display_name, :error, :avatar_url
        expose :timezone, :timezone_identifiers, :locale, decorate: false
      end
    end
  end
end
