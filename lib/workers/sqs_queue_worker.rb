# frozen_string_literal: true

class SqsQueueWorker
  def initialize(sqs_client:, queue_url:, stop:, wait_time_seconds:)
    @sqs_client = sqs_client
    @queue_url = queue_url
    @stop = stop
    @wait_time_seconds = wait_time_seconds
  end

  def thread = Thread.new { poll }

  private def poll
    loop do
      break if @stop.set?

      resp = @sqs_client.receive_message(
        queue_url: @queue_url,
        max_number_of_messages: 1,
        wait_time_seconds: @wait_time_seconds
      )
      resp.messages.each {|msg| handle(msg) }
    rescue Seahorse::Client::NetworkingError, Aws::SQS::Errors::NonExistentQueue => e
      break if @stop.set?

      warn "#{e.message}, retrying in 5 seconds..."
      sleep 5
    end
  end
end
