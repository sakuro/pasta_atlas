# frozen_string_literal: true

module LambdaSupport
  # Runs the one-off tasks (migrate, seed, delete map) and the scheduled cleanups. Only the tasks listed
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

    private def dispatch(event)
      case event["task"]
      # --no-dump: structure dumps are not wanted in production, and the Lambda image
      # has no pg_dump.
      in "db:migrate" then @cli.call(%w[db migrate --no-dump])
      in "db:seed" then @cli.call(%w[db seed])
      in "maps:delete" then delete_map(event["map_ulid"])
      in "cleanup:stale_uploads" then @rake.call("cleanup:stale_uploads")
      in "cleanup:orphaned_avatars" then @rake.call("cleanup:orphaned_avatars")
      in "cleanup:orphaned_maps" then cleanup_orphaned_maps(event["dry_run"])
      in name then raise UnknownTask, "unknown task: #{name}"
      end
    end

    # The task deletes whole map prefixes, so it only lists them unless the event says
    # "dry_run": false. The variable is reset on every call because a warm function keeps its
    # environment between invocations.
    private def cleanup_orphaned_maps(dry_run)
      if dry_run == false
        @env.delete("DRY_RUN")
      else
        @env["DRY_RUN"] = "1"
      end
      @rake.call("cleanup:orphaned_maps")
    end

    private def delete_map(ulid)
      raise ArgumentError, "map_ulid is required" unless ulid

      @env["MAP_ULID"] = ulid
      @rake.call("maps:delete")
    end
  end
end
