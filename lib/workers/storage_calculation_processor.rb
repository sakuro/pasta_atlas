# frozen_string_literal: true

require "dry/monads"

class StorageCalculationProcessor
  include Dry::Monads[:result]

  def initialize(operation:)
    @operation = operation
  end

  def call(body)
    generation_id = Integer(body, exception: false)
    return invalid(body) unless generation_id

    result = @operation.call(generation_id:)
    if result.success?
      puts "Calculated storage for generation #{generation_id}: #{result.value!} bytes"
    else
      warn "Failed to calculate storage for generation #{generation_id}: #{result.failure}"
    end
    result
  end

  private def invalid(body)
    warn "Invalid generation id: #{body.inspect}"
    Failure("invalid generation id: #{body.inspect}")
  end
end
