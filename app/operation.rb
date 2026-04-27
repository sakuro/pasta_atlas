# auto_register: false
# frozen_string_literal: true

require "dry/monads"
require "dry/operation"

module PastaAtlas
  class Operation < Dry::Operation
    include Dry::Monads[:result]
  end
end
