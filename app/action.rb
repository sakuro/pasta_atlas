# auto_register: false
# frozen_string_literal: true

require "dry/monads"
require "hanami/action"
require "json"
require "rack/icu4x/locale"

module PastaAtlas
  class Action < Hanami::Action
    include Deps["repos.user_repo", i18n_bundles: "i18n.bundles"]
    include Dry::Monads[:result]

    private def json_response(response, data, status: 200)
      response.status = status
      response.headers["Content-Type"] = "application/json"
      response.body = JSON.generate(data)
    end

    private def view_context_options(request, response)
      super.merge(i18n: build_i18n_sequence(request))
    end

    private def build_i18n_sequence(request)
      locales = request.env[::Rack::ICU4X::Locale::ENV_KEY] || [ICU4X::Locale.parse("en")]
      bundles = locales.filter_map {|locale| i18n_bundles[locale.to_s] }
      Foxtail::Sequence.new(*bundles)
    end

    private def current_user_id(request) = request.session[:user_id]

    private def current_user_or_guest_id(request)
      request.session[:user_id] || guest_user_id
    end

    private def guest_user_id = user_repo.find_by_name("guest")&.id
  end
end
