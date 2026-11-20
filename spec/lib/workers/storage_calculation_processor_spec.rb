# frozen_string_literal: true

require_relative "../../../lib/workers/storage_calculation_processor"

RSpec.describe StorageCalculationProcessor do
  include Dry::Monads[:result]

  describe "#call" do
    it "passes the generation id as an Integer and returns the result" do
      processor = StorageCalculationProcessor.new(operation: ->(generation_id:) { Success(generation_id * 10) })

      expect(processor.call("42")).to eq(Success(420))
    end

    it "logs the calculated size when calculation succeeds" do
      processor = StorageCalculationProcessor.new(operation: ->(**) { Success(1024) })

      expect { processor.call("7") }.to output("Calculated storage for generation 7: 1024 bytes\n").to_stdout
    end

    it "returns the failure when calculation fails" do
      processor = StorageCalculationProcessor.new(operation: ->(**) { Failure(:not_found) })

      expect(processor.call("7")).to eq(Failure(:not_found))
    end

    it "returns a failure without calling the operation when the body is not an integer" do
      processor = StorageCalculationProcessor.new(operation: ->(**) { raise ArgumentError, "must not be called" })

      expect(processor.call("abc")).to eq(Failure("invalid generation id: \"abc\""))
    end
  end
end
