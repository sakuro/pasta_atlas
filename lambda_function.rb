# frozen_string_literal: true

require_relative "lib/lambda_support/bootstrap"
require_relative "lib/lambda_support/sqs_batch"
require_relative "lib/lambda_support/task_runner"

# Settings are read while Hanami loads, so secrets must be in ENV first.
LambdaSupport::Bootstrap.load_secrets
require "hanami/prepare"
require_relative "lib/workers/s3_cleanup_processor"
require_relative "lib/workers/storage_calculation_processor"

# Entry points of the event functions. The app function does not use this file: it
# runs Puma through run.sh and the Lambda Web Adapter.
module LambdaFunction
  module S3Cleanup
    PROCESSOR = S3CleanupProcessor.new(operation: Hanami.app["operations.delete_s3_prefix"])
    private_constant :PROCESSOR

    def self.process(event:, **) = LambdaSupport::SqsBatch.process(event) {|body| PROCESSOR.call(body) }
  end

  module StorageCalculation
    PROCESSOR = StorageCalculationProcessor.new(operation: Hanami.app["operations.generations.calculate_storage"])
    private_constant :PROCESSOR

    def self.process(event:, **) = LambdaSupport::SqsBatch.process(event) {|body| PROCESSOR.call(body) }
  end

  module Task
    def self.process(event:, **)
      LambdaSupport::TaskRunner.new(cli: method(:run_cli), rake: method(:run_rake)).call(event)
      {"status" => "ok"}
    end

    private_class_method def self.run_cli(arguments)
      require "dry/cli"
      require "hanami/cli"
      Dry::CLI.new(Hanami::CLI).call(arguments:)
    end

    # The Lambda environment can be reused, so the Rakefile is loaded once and the
    # task is re-enabled for every invocation.
    private_class_method def self.run_rake(name)
      require "rake"
      unless Rake::Task.task_defined?(name)
        Rake.application.init("rake", [])
        Rake.application.load_rakefile
      end
      Rake::Task[name].reenable
      Rake::Task[name].invoke
    end
  end
end
