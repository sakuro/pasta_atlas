# frozen_string_literal: true

module PastaAtlas
  module Views
    module User
      class Edit < Hanami::View
        expose :display_name, :error, :avatar_url, :flash_error
        expose :timezone, :timezone_identifiers, :locale, decorate: false
        expose :providers, :connected_providers, decorate: false
      end
    end
  end
end
