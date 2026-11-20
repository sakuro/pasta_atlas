# frozen_string_literal: true

require_relative "../../../lib/lambda_support/sqs_batch"

RSpec.describe LambdaSupport::SqsBatch do
  include Dry::Monads[:result]

  let(:event) do
    {
      "Records" => [
        {"messageId" => "m1", "body" => "ok"},
        {"messageId" => "m2", "body" => "fail"},
        {"messageId" => "m3", "body" => "raise"}
      ]
    }
  end

  describe ".process" do
    it "reports failed and raising records only" do
      response = LambdaSupport::SqsBatch.process(event) {|body|
        raise ArgumentError, "boom" if body == "raise"

        body == "ok" ? Success(nil) : Failure(nil)
      }

      expect(response).to eq("batchItemFailures" => [{"itemIdentifier" => "m2"}, {"itemIdentifier" => "m3"}])
    end

    it "reports no failures when every record succeeds" do
      response = LambdaSupport::SqsBatch.process(event) { Success(nil) }

      expect(response).to eq("batchItemFailures" => [])
    end

    it "logs the error of a raising record" do
      expect {
        LambdaSupport::SqsBatch.process("Records" => [{"messageId" => "m1", "body" => "x"}]) { raise ArgumentError, "boom" }
      }.to output("ArgumentError: boom\n").to_stderr
    end
  end
end
