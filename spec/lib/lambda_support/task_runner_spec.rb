# frozen_string_literal: true

require_relative "../../../lib/lambda_support/task_runner"

RSpec.describe LambdaSupport::TaskRunner do
  let(:cli_calls) { [] }
  let(:rake_calls) { [] }
  let(:env) { {} }
  let(:rake) { ->(name) { rake_calls << name } }
  let(:runner) do
    LambdaSupport::TaskRunner.new(cli: ->(arguments) { cli_calls << arguments }, rake:, env:)
  end

  describe "#call" do
    it "migrates without dumping the structure" do
      runner.call("task" => "db:migrate")

      expect(cli_calls).to eq([%w[db migrate --no-dump]])
    end

    it "seeds the database" do
      runner.call("task" => "db:seed")

      expect(cli_calls).to eq([%w[db seed]])
    end

    it "deletes a map through the rake task with MAP_ULID set" do
      runner.call("task" => "maps:delete", "map_ulid" => "01ABC")

      expect([rake_calls, env]).to eq([["maps:delete"], {"MAP_ULID" => "01ABC"}])
    end

    it "rejects tasks that are not allow-listed" do
      expect { runner.call("task" => "db:drop") }
        .to raise_error(LambdaSupport::TaskRunner::UnknownTask, "unknown task: db:drop")
    end

    context "when a task exits with a non-zero status" do
      let(:rake) { ->(_name) { exit 2 } }

      it "raises so the invocation is reported as failed" do
        expect { runner.call("task" => "maps:delete", "map_ulid" => "01ABC") }
          .to raise_error(RuntimeError, "task exited with status 2")
      end
    end

    context "when a task exits with status 0" do
      let(:rake) { ->(_name) { exit 0 } }

      it "treats it as success" do
        expect { runner.call("task" => "maps:delete", "map_ulid" => "01ABC") }.not_to raise_error
      end
    end
  end
end
