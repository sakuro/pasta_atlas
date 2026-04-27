# auto_register: false
# frozen_string_literal: true

require "dry/monads"
require "hanami/action"

module PastaAtlas
  class Action < Hanami::Action
    # Provide `Success` and `Failure` for pattern matching on operation results
    include Dry::Monads[:result]
  end
end
