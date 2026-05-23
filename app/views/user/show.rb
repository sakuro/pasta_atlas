# frozen_string_literal: true

module PastaAtlas
  module Views
    module User
      class Show < Hanami::View
        expose :user_name, :display_name, :avatar_url, :recent_map_infos, :is_owner, :error
        expose :timezone, :timezone_identifiers, :locale, :supported_locales, :relative_timestamps, decorate: false
        expose :providers, :connected_providers, decorate: false
      end
    end
  end
end
