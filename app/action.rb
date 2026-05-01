# auto_register: false
# frozen_string_literal: true

require "dry/monads"
require "hanami/action"
require "json"

module PastaAtlas
  class Action < Hanami::Action
    include Deps["repos.user_repo"]
    include Dry::Monads[:result]

    private def json_response(response, data, status: 200)
      response.status = status
      response.headers["Content-Type"] = "application/json"
      response.body = JSON.generate(data)
    end

    private def current_user_id(request) = request.session[:user_id]

    private def current_or_guest_user_id(request)
      request.session[:user_id] || guest_user_id
    end

    private def guest_user_id = user_repo.find_by_name("guest")&.id
  end
end
