# frozen_string_literal: true

require_relative "../../../lib/workers/s3_cleanup_processor"

RSpec.describe S3CleanupProcessor do
  include Dry::Monads[:result]

  describe "#call" do
    it "returns the operation result when deletion succeeds" do
      processor = S3CleanupProcessor.new(operation: ->(s3_prefix:) { Success(s3_prefix) })

      expect(processor.call("alice/maps/1/")).to eq(Success("alice/maps/1/"))
    end

    it "logs the deleted prefix when deletion succeeds" do
      processor = S3CleanupProcessor.new(operation: ->(s3_prefix:) { Success(s3_prefix) })

      expect { processor.call("alice/maps/1/") }.to output("Deleted S3 objects under alice/maps/1/\n").to_stdout
    end

    it "returns the failure when deletion fails" do
      processor = S3CleanupProcessor.new(operation: ->(s3_prefix:) { Failure("boom for #{s3_prefix}") })

      expect(processor.call("alice/maps/1/")).to eq(Failure("boom for alice/maps/1/"))
    end

    it "logs the failure when deletion fails" do
      processor = S3CleanupProcessor.new(operation: ->(**) { Failure("boom") })

      expect { processor.call("alice/maps/1/") }
        .to output("Failed to delete S3 objects under alice/maps/1/: boom\n").to_stderr
    end
  end
end
