# frozen_string_literal: true

module LambdaSupport
  # Replaces the one-off ECS tasks (migrate, seed, delete map). Only the tasks listed
  # here can be run, whatever the invoker sends.
  class TaskRunner
    class UnknownTask < StandardError; end

    def initialize(cli:, rake:, env: ENV)
      @cli = cli
      @rake = rake
      @env = env
    end

    def call(event)
      dispatch(event)
    rescue SystemExit => e
      raise RuntimeError, "task exited with status #{e.status}" unless e.success?
    end

    # --no-dump replaces the pg_dump stub of the Dockerfile; structure dumps are not
    # wanted in production.
    private def dispatch(event)
      case event["task"]
      in "db:migrate" then @cli.call(%w[db migrate --no-dump])
      in "db:seed" then @cli.call(%w[db seed])
      in "maps:delete" then delete_map(event["map_ulid"])
      in name then raise UnknownTask, "unknown task: #{name}"
      end
    end

    private def delete_map(ulid)
      raise ArgumentError, "map_ulid is required" unless ulid

      @env["MAP_ULID"] = ulid
      @rake.call("maps:delete")
    end
  end
end
