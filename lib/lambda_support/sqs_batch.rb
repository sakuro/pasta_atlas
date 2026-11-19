# frozen_string_literal: true

module LambdaSupport
  # Only failed records are returned so SQS retries them individually. This needs
  # ReportBatchItemFailures on the event source mapping.
  module SqsBatch
    def self.process(event, &processor)
      failures = event["Records"].reject {|record| succeeded?(record, processor) }
      {"batchItemFailures" => failures.map {|record| {"itemIdentifier" => record["messageId"]} }}
    end

    private_class_method def self.succeeded?(record, processor)
      processor.call(record["body"]).success?
    rescue => e
      warn "#{e.class}: #{e.message}"
      false
    end
  end
end
