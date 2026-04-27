# frozen_string_literal: true

require "aws-sdk-s3"

# Enable AWS SDK stub responses for all tests.
# Prevents real AWS API calls; S3 operations return empty success responses by default.
Aws.config[:stub_responses] = true
