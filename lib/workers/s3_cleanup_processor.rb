# frozen_string_literal: true

class S3CleanupProcessor
  def initialize(operation:)
    @operation = operation
  end

  def call(body)
    result = @operation.call(s3_prefix: body)
    if result.success?
      puts "Deleted S3 objects under #{body}"
    else
      warn "Failed to delete S3 objects under #{body}: #{result.failure}"
    end
    result
  end
end
