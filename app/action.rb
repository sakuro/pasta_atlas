# auto_register: false
# frozen_string_literal: true

require "dry/monads"
require "hanami/action"
require "json"

module PastaAtlas
  class Action < Hanami::Action
    include Dry::Monads[:result]

    private def json_response(response, data, status: 200)
      response.status = status
      response.headers["Content-Type"] = "application/json"
      response.body = JSON.generate(data)
    end

    private def current_user_id(_request)
      nil # TODO: implement session-based authentication
    end
  end
end
