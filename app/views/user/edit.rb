# frozen_string_literal: true

module PastaAtlas
  module Views
    module User
      class Edit < Hanami::View
        expose :display_name, :timezone, :timezone_identifiers, :error, :avatar_url
        expose :locale, decorate: false
      end
    end
  end
end
