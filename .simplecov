# frozen_string_literal: true

# Configuration only: spec/spec_helper.rb calls SimpleCov.start.

SimpleCov.skip "/frontend/"
SimpleCov.skip "/node_modules/"
SimpleCov.skip "/spec/"
SimpleCov.skip "/vendor/"

SimpleCov.minimum_coverage 80.0
# SimpleCov.minimum_coverage_by_file 70

SimpleCov.enable_coverage :branch

# Coverage formats
SimpleCov.formatter SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter, # HTML report in coverage/
    SimpleCov::Formatter::SimpleFormatter # Console output
  ]
)

# Merge multiple test runs (useful for parallel testing)
SimpleCov.merge_timeout 3600
