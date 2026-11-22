# frozen_string_literal: true

require "aws-sdk-sqs"
require "concurrent-ruby"
require_relative "../../../lib/workers/sqs_queue_worker"

RSpec.describe SqsQueueWorker do
  describe "#thread" do
    it "stops during the retry delay as soon as a stop is requested" do
      stop = Concurrent::Event.new
      failed = Concurrent::Event.new
      sqs_client = instance_double(Aws::SQS::Client)
      allow(sqs_client).to receive(:receive_message) do
        failed.set
        raise Seahorse::Client::NetworkingError.new(StandardError.new("down"), "down")
      end
      worker = SqsQueueWorker.new(sqs_client:, queue_url: "queue", stop:, wait_time_seconds: 1)

      stopped = nil
      expect {
        thread = worker.thread
        failed.wait(1)
        stop.set
        stopped = thread.join(2)
      }.to output(/\A(down, retrying in 5 seconds\.\.\.\n)?\z/).to_stderr
      expect(stopped).not_to be_nil
    end
  end
end
