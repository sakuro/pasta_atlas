# auto_register: false
# frozen_string_literal: true

require "dry/monads"
require "hanami/action"
require "json"

module PastaAtlas
  class Action < Hanami::Action
    include Deps["resolvers.user_resolver", "routes", "system_users.guest"]
    include Dry::Monads[:result]

    private def json_response(response, data, status: :ok)
      response.status = status
      response.headers["Content-Type"] = "application/json"
      response.body = JSON.generate(data)
    end

    private def current_user(request) = user_resolver.call(request.session[:user_id])

    private def current_user_id(request) = request.session[:user_id] || guest_user_id

    private def guest_user_id = guest.id
  end
end
