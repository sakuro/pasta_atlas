# Lambda Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the Hanami application from ECS Fargate to AWS Lambda as described in [doc/design/16-lambda-migration.md](../design/16-lambda-migration.md).

**Architecture:** One zip (managed `ruby4.0` runtime, arm64) feeds four functions: `app` (Lambda Web Adapter + Puma behind a Function URL), `s3-cleanup` and `storage-calculation` (SQS event source mappings with DLQs) and `task` (migrate, seed, delete map). CloudFront fronts everything and adds a secret header; assets move to their own S3 bucket. Lambda runs in new private subnets that reach the internet through a fck-nat instance.

**Tech Stack:** Ruby 4.0 / Hanami 2.3 / RSpec, Terraform (AWS provider, HCP Terraform backend), GitHub Actions, AWS Lambda, CloudFront, SQS, SSM Parameter Store.

## Global Constraints

- Lambda runtime `ruby4.0` (Ruby 4.0.9 at the time of writing), architecture `arm64`, zip package; unzipped size at most 250 MB.
- Function names: `pasta-atlas-production-app`, `-s3-cleanup`, `-storage-calculation`, `-task`.
- Web Adapter layer `arn:aws:lambda:ap-northeast-1:753240598075:layer:LambdaAdapterLayerArm64:30`, `AWS_LAMBDA_EXEC_WRAPPER=/opt/bootstrap`, handler `run.sh`, `AWS_LWA_PORT=7000`, readiness path `/up`.
- Secrets live in SSM Parameter Store under `/pasta-atlas/production/`; the only secret allowed in Terraform state is the origin verification header.
- Assets bucket `pasta-atlas-production-assets` (objects under the `assets/` key prefix); artifacts bucket `pasta-atlas-production-lambda-artifacts`.
- Ruby code follows the user's rules: `private def` per method, endless methods for one-line bodies, `Pathname` only for path arguments, no numbered block parameters, no `described_class`, no RuboCop disable comments (ask the user about a `.rubocop.yml` exclusion instead), `.rubocop.yml` overrides sorted alphabetically.
- Documentation, comments and commit messages are in English (the repository is MIT-licensed). No AI attribution trailers and no session links in commits.
- Run `bundle exec rake` (RSpec and RuboCop) before every commit, even for documentation-only changes.
- If a database connection fails, stop and ask the user to start PostgreSQL (`bin/dev` or `docker compose up -d`).
- AWS commands: `cd` into the repository first, then `unset AWS_ENDPOINT_URL` (mise sets it to floci) and use `AWS_PROFILE=terraform`. Use `terraform -chdir=...` instead of `cd`.
- Commits are made only when the user approves executing this plan. Anything that changes AWS (apply, IAM edits, deleting images) needs explicit user approval at that step.

## File Structure

| Path | Responsibility |
|---|---|
| `lib/workers/s3_cleanup_processor.rb`, `storage_calculation_processor.rb` | Per-message logic shared by the local polling workers and the Lambda handlers |
| `lib/lambda_support/sqs_batch.rb` | SQS event handling with partial batch failure responses |
| `lib/lambda_support/secrets_loader.rb` | Reads SSM parameters into `ENV` |
| `lib/lambda_support/bootstrap.rb` | Calls the loader before Hanami loads |
| `lib/lambda_support/task_runner.rb` | Allow-listed one-off tasks |
| `lambda_function.rb` | Handler entry points for the event functions |
| `run.sh` | Starts Puma for the `app` function |
| `app/middleware/origin_verify.rb` | Rejects requests without the CloudFront secret header |
| `scripts/build-lambda-zip`, `scripts/invoke-lambda-task` | Package build and task invocation |
| `terraform/environments/production/` | `network.tf`, `assets.tf`, `lambda.tf` (new); `cloudfront.tf`, `iam.tf`, `sqs.tf`, `ssm.tf`, `acm.tf`, `dns.tf`, `outputs.tf`, `variables.tf`, `main.tf` (changed); `alb.tf`, `ecs.tf`, `scheduler.tf` (removed) |

---

### Task 1: Branch and baseline

**Files:**
- Modify: `Gemfile`, `Gemfile.lock`

**Interfaces:**
- Produces: `aws-sdk-ssm` available to later tasks; a green baseline.

- [ ] **Step 1: Create the working branch**

```bash
git switch -c lambda-migration
```

- [ ] **Step 2: Install gems (local bundle is behind the lockfile)**

Run: `bundle install`
Expected: completes without errors.

- [ ] **Step 3: Check the baseline**

Run: `bundle exec rake`
Expected: RSpec and RuboCop pass. If the database connection fails, stop and ask the user to start PostgreSQL.

- [ ] **Step 4: Add the SSM client gem**

Run: `bundle add aws-sdk-ssm`
Expected: `Gemfile` gains `gem "aws-sdk-ssm"` next to `aws-sdk-sqs`; keep the list alphabetical (`aws-sdk-s3`, `aws-sdk-sqs`, `aws-sdk-ssm`) by moving the line if needed.

- [ ] **Step 5: Verify and commit**

Run: `bundle exec rake`
Expected: PASS.

```bash
git add Gemfile Gemfile.lock
git commit -m ":heavy_plus_sign: Add aws-sdk-ssm for loading secrets in Lambda"
```

---

### Task 2: Message processors shared by workers and Lambda

**Files:**
- Create: `lib/workers/s3_cleanup_processor.rb`, `lib/workers/storage_calculation_processor.rb`
- Create: `spec/lib/workers/s3_cleanup_processor_spec.rb`, `spec/lib/workers/storage_calculation_processor_spec.rb`
- Modify: `lib/workers/s3_cleanup_queue_worker.rb`, `lib/workers/storage_calculation_queue_worker.rb`

**Interfaces:**
- Produces: `S3CleanupProcessor.new(operation:)#call(body) -> Dry::Monads::Result`, `StorageCalculationProcessor.new(operation:)#call(body) -> Dry::Monads::Result`. `operation` is anything responding to `call` with `s3_prefix:` or `generation_id:` keywords.

- [ ] **Step 1: Write the failing specs**

`spec/lib/workers/s3_cleanup_processor_spec.rb`:

```ruby
# frozen_string_literal: true

require_relative "../../../lib/workers/s3_cleanup_processor"

RSpec.describe S3CleanupProcessor do
  include Dry::Monads[:result]

  describe "#call" do
    it "returns the operation result when deletion succeeds" do
      processor = S3CleanupProcessor.new(operation: ->(s3_prefix:) { Success(s3_prefix) })

      expect(processor.call("alice/maps/1/")).to eq(Success("alice/maps/1/"))
    end

    it "logs the deleted prefix when deletion succeeds" do
      processor = S3CleanupProcessor.new(operation: ->(s3_prefix:) { Success(s3_prefix) })

      expect { processor.call("alice/maps/1/") }.to output("Deleted S3 objects under alice/maps/1/\n").to_stdout
    end

    it "returns the failure when deletion fails" do
      processor = S3CleanupProcessor.new(operation: ->(s3_prefix:) { Failure("boom for #{s3_prefix}") })

      expect(processor.call("alice/maps/1/")).to eq(Failure("boom for alice/maps/1/"))
    end

    it "logs the failure when deletion fails" do
      processor = S3CleanupProcessor.new(operation: ->(**) { Failure("boom") })

      expect { processor.call("alice/maps/1/") }
        .to output("Failed to delete S3 objects under alice/maps/1/: boom\n").to_stderr
    end
  end
end
```

`spec/lib/workers/storage_calculation_processor_spec.rb`:

```ruby
# frozen_string_literal: true

require_relative "../../../lib/workers/storage_calculation_processor"

RSpec.describe StorageCalculationProcessor do
  include Dry::Monads[:result]

  describe "#call" do
    it "passes the generation id as an Integer and returns the result" do
      processor = StorageCalculationProcessor.new(operation: ->(generation_id:) { Success(generation_id * 10) })

      expect(processor.call("42")).to eq(Success(420))
    end

    it "logs the calculated size when calculation succeeds" do
      processor = StorageCalculationProcessor.new(operation: ->(**) { Success(1024) })

      expect { processor.call("7") }.to output("Calculated storage for generation 7: 1024 bytes\n").to_stdout
    end

    it "returns the failure when calculation fails" do
      processor = StorageCalculationProcessor.new(operation: ->(**) { Failure(:not_found) })

      expect(processor.call("7")).to eq(Failure(:not_found))
    end

    it "returns a failure without calling the operation when the body is not an integer" do
      processor = StorageCalculationProcessor.new(operation: ->(**) { raise "must not be called" })

      expect(processor.call("abc")).to eq(Failure("invalid generation id: \"abc\""))
    end
  end
end
```

- [ ] **Step 2: Run the specs to verify they fail**

Run: `bundle exec rspec spec/lib/workers`
Expected: FAIL with `cannot load such file -- .../lib/workers/s3_cleanup_processor`.

- [ ] **Step 3: Implement the processors**

`lib/workers/s3_cleanup_processor.rb`:

```ruby
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
```

`lib/workers/storage_calculation_processor.rb`:

```ruby
# frozen_string_literal: true

require "dry/monads"

class StorageCalculationProcessor
  include Dry::Monads[:result]

  def initialize(operation:)
    @operation = operation
  end

  def call(body)
    generation_id = Integer(body, exception: false)
    return invalid(body) unless generation_id

    result = @operation.call(generation_id:)
    if result.success?
      puts "Calculated storage for generation #{generation_id}: #{result.value!} bytes"
    else
      warn "Failed to calculate storage for generation #{generation_id}: #{result.failure}"
    end
    result
  end

  private def invalid(body)
    warn "Invalid generation id: #{body.inspect}"
    Failure("invalid generation id: #{body.inspect}")
  end
end
```

- [ ] **Step 4: Run the specs to verify they pass**

Run: `bundle exec rspec spec/lib/workers`
Expected: PASS (8 examples).

- [ ] **Step 5: Use the processors in the polling workers**

`lib/workers/s3_cleanup_queue_worker.rb`:

```ruby
# frozen_string_literal: true

require_relative "s3_cleanup_processor"
require_relative "sqs_queue_worker"

class S3CleanupQueueWorker < SqsQueueWorker
  def initialize(sqs_client:, settings:, stop:, wait_time_seconds:, processor: nil)
    super(sqs_client:, queue_url: settings.sqs_s3_cleanup_queue_url, stop:, wait_time_seconds:)
    @processor = processor || S3CleanupProcessor.new(operation: Hanami.app["operations.delete_s3_prefix"])
  end

  private def handle(msg)
    return unless @processor.call(msg.body).success?

    @sqs_client.delete_message(queue_url: @queue_url, receipt_handle: msg.receipt_handle)
  end
end
```

`lib/workers/storage_calculation_queue_worker.rb`:

```ruby
# frozen_string_literal: true

require_relative "sqs_queue_worker"
require_relative "storage_calculation_processor"

class StorageCalculationQueueWorker < SqsQueueWorker
  def initialize(sqs_client:, settings:, stop:, wait_time_seconds:, processor: nil)
    super(sqs_client:, queue_url: settings.sqs_storage_calculation_queue_url, stop:, wait_time_seconds:)
    @processor = processor || StorageCalculationProcessor.new(
      operation: Hanami.app["operations.generations.calculate_storage"]
    )
  end

  private def handle(msg)
    return unless @processor.call(msg.body).success?

    @sqs_client.delete_message(queue_url: @queue_url, receipt_handle: msg.receipt_handle)
  end
end
```

- [ ] **Step 6: Verify and commit**

Run: `bundle exec rake`
Expected: PASS. Also run `bundle exec rake -T s3` and confirm `s3:process_queues` is still listed.

```bash
git add lib/workers spec/lib/workers
git commit -m ":recycle: Extract per-message logic from the SQS polling workers"
```

---

### Task 3: SQS batch helper

**Files:**
- Create: `lib/lambda_support/sqs_batch.rb`, `spec/lib/lambda_support/sqs_batch_spec.rb`

**Interfaces:**
- Produces: `LambdaSupport::SqsBatch.process(event) { |body| result } -> {"batchItemFailures" => [{"itemIdentifier" => id}]}`. The block receives each record body and returns a Result (anything responding to `success?`); a raised `StandardError` counts as a failure.

- [ ] **Step 1: Write the failing spec**

`spec/lib/lambda_support/sqs_batch_spec.rb`:

```ruby
# frozen_string_literal: true

require_relative "../../../lib/lambda_support/sqs_batch"

RSpec.describe LambdaSupport::SqsBatch do
  include Dry::Monads[:result]

  let(:event) do
    {
      "Records" => [
        {"messageId" => "m1", "body" => "ok"},
        {"messageId" => "m2", "body" => "fail"},
        {"messageId" => "m3", "body" => "raise"}
      ]
    }
  end

  describe ".process" do
    it "reports failed and raising records only" do
      response = LambdaSupport::SqsBatch.process(event) do |body|
        raise "boom" if body == "raise"

        body == "ok" ? Success(nil) : Failure(nil)
      end

      expect(response).to eq("batchItemFailures" => [{"itemIdentifier" => "m2"}, {"itemIdentifier" => "m3"}])
    end

    it "reports no failures when every record succeeds" do
      response = LambdaSupport::SqsBatch.process(event) { Success(nil) }

      expect(response).to eq("batchItemFailures" => [])
    end

    it "logs the error of a raising record" do
      expect {
        LambdaSupport::SqsBatch.process("Records" => [{"messageId" => "m1", "body" => "x"}]) { raise "boom" }
      }.to output("RuntimeError: boom\n").to_stderr
    end
  end
end
```

- [ ] **Step 2: Run to verify it fails**

Run: `bundle exec rspec spec/lib/lambda_support/sqs_batch_spec.rb`
Expected: FAIL with `cannot load such file`.

- [ ] **Step 3: Implement**

`lib/lambda_support/sqs_batch.rb`:

```ruby
# frozen_string_literal: true

module LambdaSupport
  # Only failed records are returned so SQS retries them individually. This needs
  # ReportBatchItemFailures on the event source mapping.
  module SqsBatch
    def self.process(event, &processor)
      failures = event.fetch("Records").reject {|record| succeeded?(record, processor) }
      {"batchItemFailures" => failures.map {|record| {"itemIdentifier" => record.fetch("messageId")} }}
    end

    private_class_method def self.succeeded?(record, processor)
      processor.call(record.fetch("body")).success?
    rescue StandardError => e
      warn "#{e.class}: #{e.message}"
      false
    end
  end
end
```

- [ ] **Step 4: Verify and commit**

Run: `bundle exec rspec spec/lib/lambda_support/sqs_batch_spec.rb && bundle exec rake`
Expected: PASS.

```bash
git add lib/lambda_support/sqs_batch.rb spec/lib/lambda_support/sqs_batch_spec.rb
git commit -m ":sparkles: Add partial batch failure handling for SQS-triggered functions"
```

---

### Task 4: Secrets loader and bootstrap

**Files:**
- Create: `lib/lambda_support/secrets_loader.rb`, `lib/lambda_support/bootstrap.rb`
- Create: `spec/lib/lambda_support/secrets_loader_spec.rb`, `spec/lib/lambda_support/bootstrap_spec.rb`

**Interfaces:**
- Produces: `LambdaSupport::SecretsLoader.new(ssm_client:, prefix:, env: ENV)#call` sets `SESSION_SECRET`, `GITHUB_CLIENT_SECRET`, `DISCORD_CLIENT_SECRET`, `STEAM_WEB_API_KEY`, `DATABASE_URL`, `ORIGIN_VERIFY_SECRET` from `<prefix>/<lowercase name>` and raises when a parameter is missing. `LambdaSupport::Bootstrap.load_secrets(env: ENV)` does nothing unless `SSM_PARAMETER_PREFIX` is set.

- [ ] **Step 1: Write the failing specs**

`spec/lib/lambda_support/secrets_loader_spec.rb` (`Aws.config[:stub_responses]` is already enabled by `spec/support/aws.rb`):

```ruby
# frozen_string_literal: true

require "aws-sdk-ssm"
require_relative "../../../lib/lambda_support/secrets_loader"

RSpec.describe LambdaSupport::SecretsLoader do
  let(:client) { Aws::SSM::Client.new(region: "ap-northeast-1") }
  let(:env) { {} }
  let(:loader) { LambdaSupport::SecretsLoader.new(ssm_client: client, prefix: "/pasta-atlas/production", env:) }

  def stub_parameters(values, invalid: [])
    parameters = values.map {|name, value| {name: "/pasta-atlas/production/#{name}", value:} }
    client.stub_responses(:get_parameters, parameters:, invalid_parameters: invalid)
  end

  describe "#call" do
    it "sets environment variables from the parameter values" do
      stub_parameters("session_secret" => "s", "database_url" => "postgres://db", "origin_verify_secret" => "o")

      loader.call

      expect(env).to eq("SESSION_SECRET" => "s", "DATABASE_URL" => "postgres://db", "ORIGIN_VERIFY_SECRET" => "o")
    end

    it "requests every known parameter with decryption" do
      requested = nil
      client.stub_responses(:get_parameters, lambda {|context|
        requested = context.params
        {parameters: [], invalid_parameters: []}
      })

      loader.call

      expect(requested).to eq(
        names: %w[session_secret github_client_secret discord_client_secret steam_web_api_key database_url origin_verify_secret]
          .map {|name| "/pasta-atlas/production/#{name}" },
        with_decryption: true
      )
    end

    it "raises when a parameter does not exist" do
      stub_parameters({}, invalid: ["/pasta-atlas/production/database_url"])

      expect { loader.call }.to raise_error(RuntimeError, "missing SSM parameters: /pasta-atlas/production/database_url")
    end
  end
end
```

`spec/lib/lambda_support/bootstrap_spec.rb`:

```ruby
# frozen_string_literal: true

require_relative "../../../lib/lambda_support/bootstrap"

RSpec.describe LambdaSupport::Bootstrap do
  describe ".load_secrets" do
    it "does nothing when SSM_PARAMETER_PREFIX is not set" do
      env = {}

      LambdaSupport::Bootstrap.load_secrets(env:)

      expect(env).to eq({})
    end
  end
end
```

- [ ] **Step 2: Run to verify they fail**

Run: `bundle exec rspec spec/lib/lambda_support`
Expected: FAIL with `cannot load such file` for the two new files.

- [ ] **Step 3: Implement**

`lib/lambda_support/secrets_loader.rb`:

```ruby
# frozen_string_literal: true

module LambdaSupport
  # Lambda cannot inject SSM parameters into the environment the way ECS did, so
  # they are fetched once during initialization.
  class SecretsLoader
    PARAMETERS = {
      "session_secret" => "SESSION_SECRET",
      "github_client_secret" => "GITHUB_CLIENT_SECRET",
      "discord_client_secret" => "DISCORD_CLIENT_SECRET",
      "steam_web_api_key" => "STEAM_WEB_API_KEY",
      "database_url" => "DATABASE_URL",
      "origin_verify_secret" => "ORIGIN_VERIFY_SECRET"
    }.freeze

    def initialize(ssm_client:, prefix:, env: ENV)
      @ssm_client = ssm_client
      @prefix = prefix
      @env = env
    end

    def call
      response = @ssm_client.get_parameters(names: PARAMETERS.keys.map {|name| "#{@prefix}/#{name}" }, with_decryption: true)
      raise "missing SSM parameters: #{response.invalid_parameters.join(", ")}" unless response.invalid_parameters.empty?

      response.parameters.each do |parameter|
        @env[PARAMETERS.fetch(parameter.name.delete_prefix("#{@prefix}/"))] = parameter.value
      end
    end
  end
end
```

`lib/lambda_support/bootstrap.rb`:

```ruby
# frozen_string_literal: true

module LambdaSupport
  # Hanami reads its settings while the app class is evaluated, so secrets have to
  # be in ENV before it loads. Outside Lambda SSM_PARAMETER_PREFIX is unset and
  # nothing happens.
  module Bootstrap
    def self.load_secrets(env: ENV)
      prefix = env.fetch("SSM_PARAMETER_PREFIX", nil)
      return unless prefix

      require "aws-sdk-ssm"
      require_relative "secrets_loader"
      SecretsLoader.new(ssm_client: Aws::SSM::Client.new, prefix:, env:).call
    end
  end
end
```

- [ ] **Step 4: Verify and commit**

Run: `bundle exec rspec spec/lib/lambda_support && bundle exec rake`
Expected: PASS.

```bash
git add lib/lambda_support spec/lib/lambda_support
git commit -m ":sparkles: Load secrets from SSM Parameter Store at Lambda initialization"
```

---

### Task 5: Origin verification middleware

**Files:**
- Create: `app/middleware/origin_verify.rb`, `spec/middleware/origin_verify_spec.rb`
- Modify: `config.ru`

**Interfaces:**
- Produces: `PastaAtlas::Middleware::OriginVerify.new(app, secret:)`. Requests need the `x-origin-verify` header equal to `secret`; `/up` is exempt for the Web Adapter readiness check.
- Consumes: `ORIGIN_VERIFY_SECRET` in `ENV` (Task 4).

- [ ] **Step 1: Write the failing spec**

`spec/middleware/origin_verify_spec.rb`:

```ruby
# frozen_string_literal: true

require "rack/mock"

RSpec.describe PastaAtlas::Middleware::OriginVerify do
  let(:app) { ->(_env) { [200, {"content-type" => "text/plain"}, ["ok"]] } }
  let(:request) { Rack::MockRequest.new(PastaAtlas::Middleware::OriginVerify.new(app, secret: "s3cret")) }

  describe "#call" do
    it "passes requests carrying the secret header" do
      expect(request.get("/", "HTTP_X_ORIGIN_VERIFY" => "s3cret").status).to eq(200)
    end

    it "rejects requests without the header" do
      expect(request.get("/").status).to eq(403)
    end

    it "rejects requests with a wrong secret" do
      expect(request.get("/", "HTTP_X_ORIGIN_VERIFY" => "wrong").status).to eq(403)
    end

    it "lets the readiness check path through without the header" do
      expect(request.get("/up").status).to eq(200)
    end
  end
end
```

- [ ] **Step 2: Run to verify it fails**

Run: `bundle exec rspec spec/middleware/origin_verify_spec.rb`
Expected: FAIL with `uninitialized constant PastaAtlas::Middleware::OriginVerify`.

- [ ] **Step 3: Implement**

`app/middleware/origin_verify.rb`:

```ruby
# frozen_string_literal: true

# auto_register: false

require "rack/utils"

module PastaAtlas
  module Middleware
    # The Lambda Function URL is public because CloudFront origin access control cannot
    # sign browser POST bodies. CloudFront adds a shared secret header instead, and
    # requests that bypass CloudFront are rejected here.
    class OriginVerify
      HEADER = "HTTP_X_ORIGIN_VERIFY"
      READINESS_PATH = "/up"

      def initialize(app, secret:)
        @app = app
        @secret = secret
      end

      def call(env)
        return @app.call(env) if env["PATH_INFO"] == READINESS_PATH || authorized?(env)

        [403, {"content-type" => "text/plain"}, ["Forbidden"]]
      end

      private def authorized?(env) = Rack::Utils.secure_compare(env.fetch(HEADER, ""), @secret)
    end
  end
end
```

- [ ] **Step 4: Wire it into `config.ru`**

Add at the top (after the magic comment) and before `run Hanami.app`:

```ruby
# frozen_string_literal: true

require_relative "lib/lambda_support/bootstrap"
LambdaSupport::Bootstrap.load_secrets

require "hanami/boot"
```

and, immediately above `run Hanami.app`:

```ruby
if (origin_verify_secret = ENV.fetch("ORIGIN_VERIFY_SECRET", nil))
  use PastaAtlas::Middleware::OriginVerify, secret: origin_verify_secret
end

run Hanami.app
```

- [ ] **Step 5: Verify and commit**

Run: `bundle exec rspec spec/middleware && bundle exec rake`
Expected: PASS. Then start the app (`bundle exec hanami server`) and run `curl -s -o /dev/null -w '%{http_code}\n' localhost:2300/up` (expect `200`); `ORIGIN_VERIFY_SECRET=x bundle exec hanami server` must answer `403` for `/` without the header.

```bash
git add app/middleware/origin_verify.rb spec/middleware config.ru
git commit -m ":lock: Reject requests that bypass CloudFront with a shared secret header"
```

---

### Task 6: One-off task runner

**Files:**
- Create: `lib/lambda_support/task_runner.rb`, `spec/lib/lambda_support/task_runner_spec.rb`

**Interfaces:**
- Produces: `LambdaSupport::TaskRunner.new(cli:, rake:, env: ENV)#call(event)`. `cli` is called with an argument array (`%w[db migrate --no-dump]`, `%w[db seed]`), `rake` with a task name (`"maps:delete"`). Events: `{"task" => "db:migrate"}`, `{"task" => "db:seed"}`, `{"task" => "maps:delete", "map_ulid" => "..."}`. Unknown tasks raise `LambdaSupport::TaskRunner::UnknownTask`; a non-zero `SystemExit` becomes a `RuntimeError`.

- [ ] **Step 1: Write the failing spec**

```ruby
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
```

- [ ] **Step 2: Run to verify it fails**

Run: `bundle exec rspec spec/lib/lambda_support/task_runner_spec.rb`
Expected: FAIL with `cannot load such file`.

- [ ] **Step 3: Implement**

```ruby
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
      raise "task exited with status #{e.status}" unless e.success?
    end

    private def dispatch(event)
      case event.fetch("task")
      in "db:migrate" then @cli.call(%w[db migrate --no-dump])
      in "db:seed" then @cli.call(%w[db seed])
      in "maps:delete" then delete_map(event.fetch("map_ulid"))
      in name then raise UnknownTask, "unknown task: #{name}"
      end
    end

    private def delete_map(ulid)
      @env["MAP_ULID"] = ulid
      @rake.call("maps:delete")
    end
  end
end
```

`--no-dump` replaces the `pg_dump` stub of the Dockerfile; structure dumps are not wanted in production.

- [ ] **Step 4: Verify and commit**

Run: `bundle exec rspec spec/lib/lambda_support && bundle exec rake`
Expected: PASS.

```bash
git add lib/lambda_support/task_runner.rb spec/lib/lambda_support/task_runner_spec.rb
git commit -m ":sparkles: Add an allow-listed task runner for one-off production tasks"
```

---

### Task 7: Handler entry points and Puma launcher

**Files:**
- Create: `lambda_function.rb`, `run.sh`

**Interfaces:**
- Consumes: `LambdaSupport::Bootstrap.load_secrets`, `SqsBatch.process`, `TaskRunner`, `S3CleanupProcessor`, `StorageCalculationProcessor`.
- Produces: handler strings `lambda_function.LambdaFunction::S3Cleanup.process`, `lambda_function.LambdaFunction::StorageCalculation.process`, `lambda_function.LambdaFunction::Task.process`, and `run.sh` for the `app` function.

- [ ] **Step 1: Write `lambda_function.rb`**

```ruby
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

    def self.process(event:, **) = LambdaSupport::SqsBatch.process(event) {|body| PROCESSOR.call(body) }
  end

  module StorageCalculation
    PROCESSOR = StorageCalculationProcessor.new(operation: Hanami.app["operations.generations.calculate_storage"])

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
```

- [ ] **Step 2: Write `run.sh`**

```sh
#!/bin/sh
# Started by the Lambda Web Adapter wrapper (/opt/bootstrap runs this as the handler).
set -eu

# /var/task is read-only; Bundler needs a writable home.
export HOME=/tmp
export BUNDLE_APP_CONFIG=/var/task/.bundle
export HANAMI_PORT="${AWS_LWA_PORT}"

exec bundle exec puma -C config/puma.rb
```

Run: `chmod 755 run.sh`

- [ ] **Step 3: Check syntax and the existing suite**

Run: `ruby -c lambda_function.rb && sh -n run.sh && bundle exec rake`
Expected: `Syntax OK`, no shell errors, PASS. RuboCop fixes (for example cop-driven reformatting) are applied here; do not add disable comments. If a cop cannot be satisfied, ask the user whether to add a file-level exclusion.

- [ ] **Step 4: Commit**

```bash
git add lambda_function.rb run.sh
git commit -m ":sparkles: Add Lambda handler entry points and the Puma launcher"
```

---

### Task 8: Zip build and local smoke test

**Files:**
- Create: `scripts/build-lambda-zip`
- Modify: `.gitignore` (add `dist/`)

**Interfaces:**
- Produces: `dist/lambda.zip` (root contains `run.sh`, `lambda_function.rb`, `Gemfile`, `.bundle/config`, `vendor/bundle`, `app`, `config`, `lib`, `public/assets/assets.json`).

- [ ] **Step 1: Write the build script**

`scripts/build-lambda-zip`:

```bash
#!/usr/bin/env bash
# Builds dist/lambda.zip inside the Lambda Ruby base image so native gems match the runtime.
# Requires compiled assets in public/assets and Docker.
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p dist

docker run --rm --platform linux/arm64 --entrypoint /bin/bash \
  -v "$PWD":/src:ro -v "$PWD/dist":/out \
  public.ecr.aws/lambda/ruby:4.0 -c '
    set -euo pipefail
    dnf install -y gcc make zip tar >/dev/null
    rm -rf /build && mkdir -p /build/public/assets
    cd /src
    tar --exclude=public/assets -cf - Gemfile Gemfile.lock Rakefile app config config.ru lib public lambda_function.rb run.sh \
      | tar -C /build -xf -
    cp public/assets/assets.json /build/public/assets/
    cd /build
    bundle config set --local path vendor/bundle
    bundle config set --local without development:test
    bundle install --jobs 4
    rm -rf vendor/bundle/ruby/*/cache vendor/bundle/ruby/*/doc
    find vendor/bundle -type f \( -name "*.o" -o -name "*.c" -o -name "*.h" \) -delete
    rm -f /out/lambda.zip
    zip -qr /out/lambda.zip .
  '

echo "Built dist/lambda.zip ($(du -h dist/lambda.zip | cut -f1))"
```

Run: `chmod 755 scripts/build-lambda-zip && echo "dist/" >> .gitignore`

- [ ] **Step 2: Compile assets and build**

```bash
SESSION_SECRET=dummy GITHUB_CLIENT_ID=dummy GITHUB_CLIENT_SECRET=dummy DISCORD_CLIENT_ID=dummy \
  DISCORD_CLIENT_SECRET=dummy STEAM_WEB_API_KEY=dummy S3_BUCKET=dummy \
  CLOUDFRONT_BASE_URL=https://dummy.example.com SQS_S3_CLEANUP_QUEUE_URL=https://dummy.example.com/dummy \
  SQS_STORAGE_CALCULATION_QUEUE_URL=https://dummy.example.com/dummy HANAMI_ENV=production \
  bundle exec hanami assets compile
npm run build:frontend
rm -f public/assets/vite-entries.json
scripts/build-lambda-zip
unzip -l dist/lambda.zip | tail -1
```

Expected: `Built dist/lambda.zip (...)`, unzipped total well under 250 MB (about 90 MB).

- [ ] **Step 3: Smoke-test `app` in the Lambda runtime emulator**

Fetch the adapter layer once (needs AWS access; read-only):

```bash
cd /Users/sakuro/github.com/sakuro/pasta_atlas && unset AWS_ENDPOINT_URL
URL=$(AWS_PROFILE=terraform aws lambda get-layer-version-by-arn --region ap-northeast-1 \
  --arn arn:aws:lambda:ap-northeast-1:753240598075:layer:LambdaAdapterLayerArm64:30 --query Content.Location --output text)
mkdir -p dist/layer dist/task && curl -sS -o dist/layer.zip "$URL" && unzip -q -o dist/layer.zip -d dist/layer
unzip -q -o dist/lambda.zip -d dist/task
```

Create `dist/smoke.env` (the database must be running: `docker compose up -d postgres`, then `bundle exec hanami db prepare` once for `pasta_atlas_development`):

```
HANAMI_ENV=production
AWS_LWA_PORT=7000
AWS_LWA_READINESS_CHECK_PATH=/up
AWS_LAMBDA_EXEC_WRAPPER=/opt/bootstrap
_HANDLER=run.sh
SESSION_SECRET=smoke-test-session-secret-smoke-test-session-secret-0123456789
GITHUB_CLIENT_ID=dummy
GITHUB_CLIENT_SECRET=dummy
DISCORD_CLIENT_ID=dummy
DISCORD_CLIENT_SECRET=dummy
STEAM_WEB_API_KEY=dummy
S3_BUCKET=dummy
CLOUDFRONT_BASE_URL=https://dummy.example.com
SQS_S3_CLEANUP_QUEUE_URL=https://dummy.example.com/dummy
SQS_STORAGE_CALCULATION_QUEUE_URL=https://dummy.example.com/dummy
DATABASE_URL=postgres://pasta_atlas:pasta_atlas@host.docker.internal:5432/pasta_atlas_development
ORIGIN_VERIFY_SECRET=smoke
APP_BASE_URL=https://pasta-atlas.layer8.works
HOME=/tmp
```

Start the function and invoke it with Function URL style events:

```bash
docker run -d --name smoke-app --platform linux/arm64 --env-file dist/smoke.env -p 9000:8080 \
  -v "$PWD/dist/task":/var/task:ro -v "$PWD/dist/layer":/opt:ro \
  --entrypoint /usr/local/bin/aws-lambda-rie public.ecr.aws/lambda/ruby:4.0 /opt/bootstrap
sleep 15
event() { printf '{"version":"2.0","routeKey":"$default","rawPath":"%s","rawQueryString":"","headers":{"host":"x.lambda-url.ap-northeast-1.on.aws"%s},"requestContext":{"http":{"method":"GET","path":"%s","protocol":"HTTP/1.1","sourceIp":"1.2.3.4"}},"isBase64Encoded":false}' "$1" "$2" "$1"; }
for case in '/up|' '/|' '/|,"x-origin-verify":"smoke"'; do
  path=${case%%|*}; extra=${case#*|}
  curl -s -XPOST http://localhost:9000/2015-03-31/functions/function/invocations -d "$(event "$path" "$extra")" | head -c 160; echo
done
docker logs smoke-app 2>&1 | tail -20
```

Expected: `/up` returns `"statusCode":200`; `/` without the header returns `"statusCode":403`; `/` with `x-origin-verify: smoke` returns `"statusCode":200` (HTML). If Puma fails to start, the logs show the error; fix the zip contents (for example a missing file in the `tar` list) and rebuild. Record the first-invoke time from the logs for the design document's cold start item.

- [ ] **Step 4: Smoke-test the event and task functions**

```bash
docker rm -f smoke-app
docker run -d --name smoke-task --platform linux/arm64 --env-file dist/smoke.env -e _HANDLER= -p 9000:8080 \
  -v "$PWD/dist/task":/var/task:ro public.ecr.aws/lambda/ruby:4.0 lambda_function.LambdaFunction::Task.process
sleep 5
for i in 1 2; do
  curl -s -XPOST http://localhost:9000/2015-03-31/functions/function/invocations -d '{"task":"db:migrate"}'; echo
done
curl -s -XPOST http://localhost:9000/2015-03-31/functions/function/invocations -d '{"task":"db:drop"}'; echo
curl -s -XPOST http://localhost:9000/2015-03-31/functions/function/invocations -d '{"task":"maps:delete","map_ulid":"NOPE"}'; echo
curl -s -XPOST http://localhost:9000/2015-03-31/functions/function/invocations -d '{"task":"maps:delete","map_ulid":"NOPE"}'; echo
docker rm -f smoke-task
```

Expected: both `db:migrate` calls return `{"status":"ok"}`; `db:drop` returns an error payload containing `unknown task: db:drop`; both `maps:delete` calls return `{"status":"ok"}` and the logs say `Map not found: NOPE` twice (the second call proves the task re-enables). Then check the SQS handler wiring:

```bash
docker run -d --name smoke-sqs --platform linux/arm64 --env-file dist/smoke.env -e _HANDLER= -p 9000:8080 \
  -v "$PWD/dist/task":/var/task:ro public.ecr.aws/lambda/ruby:4.0 lambda_function.LambdaFunction::S3Cleanup.process
sleep 5
curl -s -XPOST http://localhost:9000/2015-03-31/functions/function/invocations \
  -d '{"Records":[{"messageId":"m1","body":"nobody/maps/1/"}]}'; echo
docker rm -f smoke-sqs
```

Expected: `{"batchItemFailures":[{"itemIdentifier":"m1"}]}` (the dummy bucket and missing credentials make deletion fail, which proves the failure path). If any command reports a load error, the fix belongs in Tasks 6-8.

- [ ] **Step 5: Commit**

Run: `bundle exec rake`
Expected: PASS.

```bash
git add scripts/build-lambda-zip .gitignore
git commit -m ":package: Add a script that builds the Lambda zip in the runtime image"
```

---

### Task 9: Terraform providers and network

**Files:**
- Modify: `terraform/environments/production/main.tf`, `variables.tf`, `alb.tf` (move `app_egress` out)
- Create: `terraform/environments/production/network.tf`

**Interfaces:**
- Produces: `aws_subnet.private` (list of 2), `aws_route_table.private`, `data.aws_vpc.default` reuse, `var.private_subnet_cidrs`.

- [ ] **Step 1: Add providers**

In `main.tf`, extend `required_providers`:

```hcl
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
```

- [ ] **Step 2: Check free CIDR ranges in the default VPC**

Run (after `cd` into the repository and `unset AWS_ENDPOINT_URL`):

```bash
AWS_PROFILE=terraform aws ec2 describe-subnets --region ap-northeast-1 \
  --filters Name=vpc-id,Values=$(AWS_PROFILE=terraform aws ec2 describe-vpcs --region ap-northeast-1 --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text) \
  --query 'Subnets[].CidrBlock' --output text
```

Expected: the default subnets (for example `172.31.0.0/20 172.31.16.0/20 172.31.32.0/20`). The defaults below (`172.31.128.0/20`, `172.31.144.0/20`) must not overlap any of them.

- [ ] **Step 3: Add the variable**

Append to `variables.tf`:

```hcl
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["172.31.128.0/20", "172.31.144.0/20"]
}

variable "app_dns_enabled" {
  type    = bool
  default = false
}
```

- [ ] **Step 4: Write `network.tf` and move the egress rule**

Delete `aws_vpc_security_group_egress_rule.app_egress` from `alb.tf` and put it in `network.tf` unchanged:

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  private_azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

data "aws_subnet" "nat_public" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = local.private_azs[0]
  default_for_az    = true
}

resource "aws_subnet" "private" {
  count             = length(local.private_azs)
  vpc_id            = data.aws_vpc.default.id
  availability_zone = local.private_azs[count.index]
  cidr_block        = var.private_subnet_cidrs[count.index]

  tags = {
    Name = "${var.app_name}-${var.environment}-private-${local.private_azs[count.index]}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id

  tags = {
    Name = "${var.app_name}-${var.environment}-private"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Lambda ENIs have no public address, so outbound traffic (OAuth providers, SQS)
# goes through a NAT instance. S3 uses the free gateway endpoint instead.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = data.aws_vpc.default.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
}

resource "aws_vpc_security_group_egress_rule" "app_egress" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
```

- [ ] **Step 5: Add fck-nat**

Look up the module and its inputs before using it:

```bash
curl -s https://registry.terraform.io/v1/modules/RaJiska/fck-nat/aws | jq -r '.version'
```

Add to `network.tf`, using that version for `version` and checking the input names against `.terraform/modules/fck_nat/README.md` after `terraform init`:

```hcl
module "fck_nat" {
  source  = "RaJiska/fck-nat/aws"
  version = "<version printed above>"

  name                = "${var.app_name}-${var.environment}-nat"
  vpc_id              = data.aws_vpc.default.id
  subnet_id           = data.aws_subnet.nat_public.id
  instance_type       = "t4g.nano"
  ha_mode             = true
  update_route_tables = true
  route_tables_ids    = { private = aws_route_table.private.id }
}
```

If the README names the inputs differently (for example for the private CIDR allow-list on its security group), adjust the arguments to match and keep the behaviour: one `t4g.nano` instance in an Auto Scaling group of one, routing the private route table's default route to it.

- [ ] **Step 6: Validate and review the plan**

```bash
cd /Users/sakuro/github.com/sakuro/pasta_atlas && unset AWS_ENDPOINT_URL
export AWS_PROFILE=terraform
terraform -chdir=terraform/environments/production init -input=false
terraform -chdir=terraform/environments/production fmt
terraform -chdir=terraform/environments/production validate
terraform -chdir=terraform/environments/production plan -lock=false -input=false -no-color | grep -E "^\s*# |^Plan:"
```

Expected: `validate` succeeds; the plan adds the subnets, route table, associations, endpoint and the module's resources, and changes nothing existing except what the original plan already showed.

- [ ] **Step 7: Commit**

```bash
git add terraform
git commit -m ":sparkles: Add private subnets, an fck-nat instance and an S3 endpoint"
```

---

### Task 10: Assets bucket

**Files:**
- Create: `terraform/environments/production/assets.tf`

**Interfaces:**
- Produces: `aws_s3_bucket.assets`, `aws_cloudfront_origin_access_control.assets` (consumed by Task 13). The bucket policy references `aws_cloudfront_distribution.app` (defined in Task 13; `validate` passes once that resource exists, which it already does as the ALB version).

- [ ] **Step 1: Write `assets.tf`**

```hcl
resource "aws_s3_bucket" "assets" {
  bucket = "${var.app_name}-${var.environment}-assets"
}

resource "aws_s3_bucket_ownership_controls" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "assets" {
  name                              = "${var.app_name}-${var.environment}-assets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_iam_policy_document" "assets_cloudfront_read" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.app.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.assets_cloudfront_read.json

  depends_on = [aws_s3_bucket_public_access_block.assets]
}
```

- [ ] **Step 2: Validate and commit**

Run: `terraform -chdir=terraform/environments/production fmt && terraform -chdir=terraform/environments/production validate`
Expected: success.

```bash
git add terraform
git commit -m ":sparkles: Add a bucket for compiled assets served through CloudFront"
```

---

### Task 11: Secrets, IAM, SQS dead-letter queues, logs and artifacts bucket

**Files:**
- Create: `terraform/environments/production/lambda_support.tf`
- Modify: `iam.tf`, `sqs.tf`, `ssm.tf` (no change expected), `variables.tf`

**Interfaces:**
- Produces: `random_password.origin_verify`, `aws_ssm_parameter.origin_verify_secret`, `aws_s3_bucket.lambda_artifacts`, `aws_cloudwatch_log_group.lambda["app"|"s3-cleanup"|"storage-calculation"|"task"]`, DLQs. The role `aws_iam_role.app` becomes the Lambda execution role.

- [ ] **Step 1: Change the role to a Lambda execution role (`iam.tf`)**

Replace the trust policy principal and add the managed policy attachment:

```hcl
data "aws_iam_policy_document" "app_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "app_lambda_vpc" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
```

Rename the comment above the role to `# IAM execution role for the Lambda functions`. Leave the `execution_ssm` attachment for Task 14 (it disappears with the ECS execution role).

- [ ] **Step 2: Dead-letter queues and visibility timeout (`sqs.tf`)**

```hcl
locals {
  # Visibility timeout is six times the worker function timeout, as AWS recommends.
  worker_timeout_seconds = 60
}

resource "aws_sqs_queue" "s3_cleanup_dlq" {
  name                      = "${var.app_name}-${var.environment}-s3-cleanup-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "storage_calculation_dlq" {
  name                      = "${var.app_name}-${var.environment}-storage-calculation-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "s3_cleanup" {
  name                       = "${var.app_name}-${var.environment}-s3-cleanup"
  visibility_timeout_seconds = local.worker_timeout_seconds * 6

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.s3_cleanup_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue" "storage_calculation" {
  name                       = "${var.app_name}-${var.environment}-storage-calculation"
  visibility_timeout_seconds = local.worker_timeout_seconds * 6

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.storage_calculation_dlq.arn
    maxReceiveCount     = 5
  })
}
```

(Replace the two existing queue resources; their names do not change, so nothing is recreated.)

- [ ] **Step 3: Write `lambda_support.tf`**

```hcl
resource "random_password" "origin_verify" {
  length  = 48
  special = false
}

# Unlike the other secrets this value must appear in the CloudFront configuration,
# so it is generated by Terraform and is part of the state.
resource "aws_ssm_parameter" "origin_verify_secret" {
  name  = "/${var.app_name}/${var.environment}/origin_verify_secret"
  type  = "SecureString"
  value = random_password.origin_verify.result
}

resource "aws_s3_bucket" "lambda_artifacts" {
  bucket = "${var.app_name}-${var.environment}-lambda-artifacts"
}

resource "aws_s3_bucket_public_access_block" "lambda_artifacts" {
  bucket = aws_s3_bucket.lambda_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "lambda_artifacts" {
  bucket = aws_s3_bucket.lambda_artifacts.id

  rule {
    id     = "expire-old-packages"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }
  }
}

locals {
  lambda_function_names = {
    app                 = "${var.app_name}-${var.environment}-app"
    s3-cleanup          = "${var.app_name}-${var.environment}-s3-cleanup"
    storage-calculation = "${var.app_name}-${var.environment}-storage-calculation"
    task                = "${var.app_name}-${var.environment}-task"
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  for_each = local.lambda_function_names

  name              = "/aws/lambda/${each.value}"
  retention_in_days = 30
}
```

- [ ] **Step 4: Validate, review and commit**

Run: `terraform -chdir=terraform/environments/production fmt && terraform -chdir=terraform/environments/production validate && terraform -chdir=terraform/environments/production plan -lock=false -input=false -no-color | grep -E "^\s*# |^Plan:"`
Expected: success; the plan shows the SQS queues updated in place (visibility and redrive), no queue replaced, no destroy beyond the original plan.

```bash
git add terraform
git commit -m ":sparkles: Add dead-letter queues, Lambda logs, artifacts bucket and the origin secret"
```

---

### Task 12: Lambda functions

**Files:**
- Create: `terraform/environments/production/lambda.tf`
- Modify: `variables.tf`

**Interfaces:**
- Produces: `aws_lambda_function.{app,s3_cleanup,storage_calculation,task}`, `aws_lambda_function_url.app` (`function_url` consumed by Task 13).

- [ ] **Step 1: Check the concurrency quota and the provider**

```bash
cd /Users/sakuro/github.com/sakuro/pasta_atlas && unset AWS_ENDPOINT_URL
AWS_PROFILE=terraform aws lambda get-account-settings --region ap-northeast-1 \
  --query '{total:AccountLimit.ConcurrentExecutions,unreserved:AccountLimit.UnreservedConcurrentExecutions}'
terraform -chdir=terraform/environments/production providers
grep -A2 'provider "registry.terraform.io/hashicorp/aws"' terraform/environments/production/.terraform.lock.hcl
```

Expected: if `unreserved` is at least 20, keep `app_reserved_concurrency = 10`; otherwise set it to `-1` in Step 2 (a reserved limit must leave at least 10 unreserved executions) and tell the user the cost cap is not available. Note the AWS provider version; Step 3 needs `invoked_via_function_url`.

- [ ] **Step 2: Add variables**

```hcl
variable "lambda_runtime" {
  type    = string
  default = "ruby4.0"
}

variable "web_adapter_layer_arn" {
  type    = string
  default = "arn:aws:lambda:ap-northeast-1:753240598075:layer:LambdaAdapterLayerArm64:30"
}

variable "app_memory_size" {
  type    = number
  default = 1024
}

variable "app_reserved_concurrency" {
  type    = number
  default = 10
}
```

- [ ] **Step 3: Write `lambda.tf`**

```hcl
# The real package is uploaded by the deploy workflow; Terraform only needs something
# to create the functions with.
data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/.terraform/placeholder.zip"

  source {
    content  = "def handler(event:, context:) = nil\n"
    filename = "placeholder.rb"
  }
}

locals {
  lambda_environment = {
    HANAMI_ENV                        = var.environment
    SSM_PARAMETER_PREFIX              = "/${var.app_name}/${var.environment}"
    APP_BASE_URL                      = "https://${var.app_domain_name}"
    S3_BUCKET                         = aws_s3_bucket.mapshots.bucket
    CLOUDFRONT_BASE_URL               = "https://${aws_cloudfront_distribution.mapshots.domain_name}"
    SQS_S3_CLEANUP_QUEUE_URL          = aws_sqs_queue.s3_cleanup.url
    SQS_STORAGE_CALCULATION_QUEUE_URL = aws_sqs_queue.storage_calculation.url
    PRESIGNED_URL_EXPIRY              = tostring(var.presigned_url_expiry)
    GITHUB_CLIENT_ID                  = var.github_client_id
    DISCORD_CLIENT_ID                 = var.discord_client_id
    # /var/task is read-only and Bundler needs a writable home in every function.
    HOME = "/tmp"
  }

  lambda_vpc = {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.app.id]
  }
}

resource "aws_lambda_function" "app" {
  function_name = local.lambda_function_names["app"]
  role          = aws_iam_role.app.arn
  runtime       = var.lambda_runtime
  architectures = ["arm64"]
  handler       = "run.sh"
  memory_size   = var.app_memory_size
  timeout       = 30
  layers        = [var.web_adapter_layer_arn]

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  reserved_concurrent_executions = var.app_reserved_concurrency

  vpc_config {
    subnet_ids         = local.lambda_vpc.subnet_ids
    security_group_ids = local.lambda_vpc.security_group_ids
  }

  environment {
    variables = merge(local.lambda_environment, {
      AWS_LAMBDA_EXEC_WRAPPER      = "/opt/bootstrap"
      AWS_LWA_PORT                 = "7000"
      AWS_LWA_READINESS_CHECK_PATH = "/up"
    })
  }

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy_attachment.app_lambda_vpc]

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_lambda_function_url" "app" {
  function_name      = aws_lambda_function.app.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "app_url" {
  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.app.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

# Function URLs created after October 2025 also need lambda:InvokeFunction.
resource "aws_lambda_permission" "app_url_invoke" {
  statement_id             = "FunctionURLAllowInvokeAction"
  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.app.function_name
  principal                = "*"
  invoked_via_function_url = true
}

resource "aws_lambda_function" "s3_cleanup" {
  function_name = local.lambda_function_names["s3-cleanup"]
  role          = aws_iam_role.app.arn
  runtime       = var.lambda_runtime
  architectures = ["arm64"]
  handler       = "lambda_function.LambdaFunction::S3Cleanup.process"
  memory_size   = 512
  timeout       = local.worker_timeout_seconds

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  vpc_config {
    subnet_ids         = local.lambda_vpc.subnet_ids
    security_group_ids = local.lambda_vpc.security_group_ids
  }

  environment {
    variables = local.lambda_environment
  }

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy_attachment.app_lambda_vpc]

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_lambda_function" "storage_calculation" {
  function_name = local.lambda_function_names["storage-calculation"]
  role          = aws_iam_role.app.arn
  runtime       = var.lambda_runtime
  architectures = ["arm64"]
  handler       = "lambda_function.LambdaFunction::StorageCalculation.process"
  memory_size   = 512
  timeout       = local.worker_timeout_seconds

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  vpc_config {
    subnet_ids         = local.lambda_vpc.subnet_ids
    security_group_ids = local.lambda_vpc.security_group_ids
  }

  environment {
    variables = local.lambda_environment
  }

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy_attachment.app_lambda_vpc]

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_lambda_function" "task" {
  function_name = local.lambda_function_names["task"]
  role          = aws_iam_role.app.arn
  runtime       = var.lambda_runtime
  architectures = ["arm64"]
  handler       = "lambda_function.LambdaFunction::Task.process"
  memory_size   = 1024
  timeout       = 900

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  vpc_config {
    subnet_ids         = local.lambda_vpc.subnet_ids
    security_group_ids = local.lambda_vpc.security_group_ids
  }

  environment {
    variables = local.lambda_environment
  }

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy_attachment.app_lambda_vpc]

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_lambda_event_source_mapping" "s3_cleanup" {
  event_source_arn        = aws_sqs_queue.s3_cleanup.arn
  function_name           = aws_lambda_function.s3_cleanup.arn
  batch_size              = 1
  function_response_types = ["ReportBatchItemFailures"]

  # Keeps database connections within what the RDS instance accepts.
  scaling_config {
    maximum_concurrency = 2
  }
}

resource "aws_lambda_event_source_mapping" "storage_calculation" {
  event_source_arn        = aws_sqs_queue.storage_calculation.arn
  function_name           = aws_lambda_function.storage_calculation.arn
  batch_size              = 1
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = 2
  }
}
```

If `terraform validate` rejects `invoked_via_function_url`, the installed provider predates it: upgrade within the pinned range (`terraform init -upgrade`, then review the lock file diff) and, if still unsupported, raise the AWS provider constraint to the first version that supports it after checking the changelog with the user.

- [ ] **Step 4: Validate and commit**

Run: `terraform -chdir=terraform/environments/production fmt && terraform -chdir=terraform/environments/production validate`
Expected: success (the CloudFront reference to the Lambda comes in Task 13).

```bash
git add terraform
git commit -m ":sparkles: Define the Lambda functions, Function URL and SQS event source mappings"
```

---

### Task 13: CloudFront, DNS and ACM

**Files:**
- Modify: `terraform/environments/production/cloudfront.tf`, `dns.tf`, `acm.tf`

**Interfaces:**
- Consumes: `aws_lambda_function_url.app`, `random_password.origin_verify`, `aws_s3_bucket.assets`, `aws_cloudfront_origin_access_control.assets`.

- [ ] **Step 1: Rewrite the `app` distribution (`cloudfront.tf`)**

Replace the whole `resource "aws_cloudfront_distribution" "app"` block:

```hcl
resource "aws_cloudfront_distribution" "app" {
  origin {
    domain_name = trimsuffix(trimprefix(aws_lambda_function_url.app.function_url, "https://"), "/")
    origin_id   = "lambda"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "x-origin-verify"
      value = random_password.origin_verify.result
    }
  }

  origin {
    domain_name              = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id                = "assets"
    origin_access_control_id = aws_cloudfront_origin_access_control.assets.id
  }

  enabled         = true
  is_ipv6_enabled = true
  price_class     = var.cloudfront_price_class
  aliases         = [var.app_domain_name]

  ordered_cache_behavior {
    path_pattern           = "/assets/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "assets"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "lambda"
    viewer_protocol_policy   = "redirect-to-https"
    compress                 = true
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cloudfront.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
```

`AllViewerExceptHostHeader` must stay: forwarding the viewer `Host` makes the Function URL answer 404.

- [ ] **Step 2: Gate the application DNS record (`dns.tf`)**

```hcl
resource "gandi_livedns_record" "app" {
  count = var.app_dns_enabled ? 1 : 0

  zone   = "layer8.works"
  name   = trimsuffix(var.app_domain_name, ".layer8.works")
  type   = "CNAME"
  ttl    = 300
  values = ["${aws_cloudfront_distribution.app.domain_name}."]
}
```

(The `maps` record is unchanged.)

- [ ] **Step 3: Keep the CloudFront certificate validation records (`acm.tf`)**

The CloudFront certificate validates through the records that belong to the ALB certificate (same domain, same values). Moving the resource keeps the real DNS records and removes the ALB certificate:

1. Replace the `aws_acm_certificate_validation.cloudfront` records reference and rename the record resource:

```hcl
resource "aws_acm_certificate_validation" "cloudfront" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.cloudfront.arn

  validation_record_fqdns = [
    for record in gandi_livedns_record.cloudfront_validation : "${record.name}.layer8.works"
  ]
}

moved {
  from = gandi_livedns_record.alb_validation
  to   = gandi_livedns_record.cloudfront_validation
}

resource "gandi_livedns_record" "cloudfront_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone   = "layer8.works"
  name   = trimsuffix(each.value.name, ".layer8.works.")
  type   = each.value.type
  ttl    = 300
  values = [each.value.value]
}
```

2. Delete `aws_acm_certificate.alb` and `aws_acm_certificate_validation.alb`, and the comment line "DNS validation records are identical to the ALB cert for the same domain."

- [ ] **Step 4: Validate and review the plan**

Run:

```bash
terraform -chdir=terraform/environments/production fmt
terraform -chdir=terraform/environments/production validate
terraform -chdir=terraform/environments/production plan -lock=false -input=false -no-color | grep -E "^\s*# |^Plan:|moved|destroyed"
```

Expected: the `gandi_livedns_record.alb_validation` shows as moved (not destroyed or created); the ALB certificate is the only ACM destroy; the ALB, listeners and target group still exist because Task 14 removes them.

- [ ] **Step 5: Commit**

```bash
git add terraform
git commit -m ":sparkles: Point the app distribution at Lambda and the assets bucket"
```

---

### Task 14: Remove the ECS stack

**Files:**
- Delete: `terraform/environments/production/alb.tf`, `ecs.tf`, `scheduler.tf`
- Modify: `iam.tf`, `outputs.tf`, `variables.tf`, `terraform/README.md`

- [ ] **Step 1: Delete the files and fix references**

```bash
git rm terraform/environments/production/alb.tf terraform/environments/production/ecs.tf terraform/environments/production/scheduler.tf
```

In `iam.tf`, delete `aws_iam_role_policy_attachment.execution_ssm` (the `execution` role is gone). In `outputs.tf`, delete the `ecr_repository_url` output. In `variables.tf`, delete `container_port`, `container_cpu`, `container_memory` and `app_desired_count`. Remove the now-unused `data "aws_ec2_managed_prefix_list" "cloudfront"` if it is still defined anywhere (it lived in `alb.tf`).

Also add outputs for the deploy workflow:

```hcl
output "lambda_artifacts_bucket" {
  value = aws_s3_bucket.lambda_artifacts.bucket
}

output "assets_bucket" {
  value = aws_s3_bucket.assets.bucket
}

output "app_cloudfront_domain_name" {
  value = aws_cloudfront_distribution.app.domain_name
}
```

- [ ] **Step 2: Update `terraform/README.md`**

Replace the rows for `alb.tf`, `ecs.tf` and `scheduler.tf` with `network.tf` (private subnets, fck-nat, S3 endpoint), `assets.tf` (assets bucket), `lambda.tf` (Lambda functions, Function URL, event source mappings) and `lambda_support.tf` (origin secret, artifacts bucket, log groups); change the `outputs.tf` row to mention `rds_endpoint` and the bucket outputs.

- [ ] **Step 3: Validate and review the full plan**

```bash
terraform -chdir=terraform/environments/production fmt -check
terraform -chdir=terraform/environments/production validate
terraform -chdir=terraform/environments/production plan -lock=false -input=false -no-color | grep -E "^\s*# |^Plan:"
```

Expected: `Plan:` shows additions for the new stack and destroys only for ECS (cluster, worker service, task definitions, log group, execution role and policy attachments), ECR (repository and lifecycle policy), the ALB security group and its rules, the ALB certificate and its validation. It must not destroy the RDS instance, the `mapshots` bucket, the SQS queues, the `maps` distribution or any SSM parameter. Show the plan summary to the user.

- [ ] **Step 4: Commit**

```bash
git add terraform
git commit -m ":fire: Remove the ECS, ALB, ECR and scheduler resources"
```

---

### Task 15: GitHub Actions and scripts

**Files:**
- Create: `scripts/invoke-lambda-task`
- Modify: `.github/workflows/deploy.yml`, `migrate.yml`, `seed.yml`, `delete-map.yml`, `scripts/seed-db`

**Interfaces:**
- Produces: `scripts/invoke-lambda-task '<json payload>'`. The workflows use the same action SHAs as the existing ones.

- [ ] **Step 1: Write `scripts/invoke-lambda-task`**

```bash
#!/usr/bin/env bash
# Invokes the production task function and fails when the function reports an error.
# Usage: scripts/invoke-lambda-task '{"task":"db:migrate"}'
set -euo pipefail

FUNCTION=${TASK_FUNCTION:-pasta-atlas-production-task}
RESPONSE=$(mktemp)
trap 'rm -f "$RESPONSE"' EXIT

# The default CLI read timeout (60 s) is shorter than the function timeout (900 s).
RESULT=$(aws lambda invoke \
  --function-name "$FUNCTION" \
  --cli-binary-format raw-in-base64-out \
  --cli-read-timeout 900 \
  --payload "$1" \
  --log-type Tail \
  --output json \
  "$RESPONSE")

echo "$RESULT" | jq -r '.LogResult // empty' | base64 --decode
if [ -n "$(echo "$RESULT" | jq -r '.FunctionError // empty')" ]; then
  cat "$RESPONSE" >&2
  exit 1
fi
```

Run: `chmod 755 scripts/invoke-lambda-task`

- [ ] **Step 2: Rewrite `scripts/seed-db`**

```bash
#!/usr/bin/env bash
# Runs `hanami db seed` against the production RDS through the task Lambda function.
# Requires: aws CLI with AWS_PROFILE=terraform configured
set -euo pipefail

unset AWS_ENDPOINT_URL
export AWS_PROFILE=terraform
export AWS_REGION=ap-northeast-1

exec "$(dirname "$0")/invoke-lambda-task" '{"task":"db:seed"}'
```

- [ ] **Step 3: Rewrite `.github/workflows/deploy.yml`**

```yaml
name: Deploy

on:
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

env:
  AWS_REGION: ap-northeast-1
  ARTIFACTS_BUCKET: pasta-atlas-production-lambda-artifacts
  ASSETS_BUCKET: pasta-atlas-production-assets
  FUNCTIONS: pasta-atlas-production-app pasta-atlas-production-s3-cleanup pasta-atlas-production-storage-calculation pasta-atlas-production-task

jobs:
  deploy:
    # An arm64 runner builds native gems for the arm64 Lambda runtime without emulation.
    runs-on: ubuntu-24.04-arm

    steps:
      - name: Checkout
        uses: actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803 # v6.1.0
        with:
          persist-credentials: false

      - uses: actions/setup-node@249970729cb0ef3589644e2896645e5dc5ba9c38 # v6.5.0
        with:
          node-version: "26"
          cache: npm

      - run: npm ci

      - uses: ruby/setup-ruby@afeafc3d1ab54a631816aba4c914a0081c12ff2f # v1.310.0
        with:
          ruby-version: "4.0"
          bundler-cache: true

      - name: Compile assets
        run: |
          bundle exec hanami assets compile
          npm run build:frontend
          rm -f public/assets/vite-entries.json
        env:
          SESSION_SECRET: dummy
          GITHUB_CLIENT_ID: dummy
          GITHUB_CLIENT_SECRET: dummy
          DISCORD_CLIENT_ID: dummy
          DISCORD_CLIENT_SECRET: dummy
          STEAM_WEB_API_KEY: dummy
          S3_BUCKET: dummy
          CLOUDFRONT_BASE_URL: https://dummy.example.com
          SQS_S3_CLEANUP_QUEUE_URL: https://dummy.example.com/dummy
          SQS_STORAGE_CALCULATION_QUEUE_URL: https://dummy.example.com/dummy
          HANAMI_ENV: production

      - name: Build package
        run: scripts/build-lambda-zip

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-cicd
          aws-region: ${{ env.AWS_REGION }}

      - name: Upload package
        run: aws s3 cp dist/lambda.zip "s3://$ARTIFACTS_BUCKET/$GITHUB_SHA.zip"

      # Assets are uploaded before the code so that pages served by the new code can
      # always find their files. Nothing is deleted: older fingerprinted files stay valid.
      - name: Sync assets
        run: |
          aws s3 sync public/assets "s3://$ASSETS_BUCKET/assets/" \
            --cache-control "public, max-age=86400" --no-progress

      - name: Update functions
        run: |
          for FUNCTION in $FUNCTIONS; do
            aws lambda update-function-code \
              --function-name "$FUNCTION" \
              --s3-bucket "$ARTIFACTS_BUCKET" \
              --s3-key "$GITHUB_SHA.zip" \
              --no-cli-pager > /dev/null
          done
          for FUNCTION in $FUNCTIONS; do
            aws lambda wait function-updated --function-name "$FUNCTION"
            echo "Updated: $FUNCTION"
          done

      - name: Invalidate CloudFront cache
        run: |
          DIST_ID=$(aws cloudfront list-distributions \
            --query "DistributionList.Items[?contains(Aliases.Items, 'pasta-atlas.layer8.works')].Id" \
            --output text)
          aws cloudfront create-invalidation \
            --distribution-id "$DIST_ID" \
            --paths "/assets/ftl-manifest.json" \
            --no-cli-pager > /dev/null
          echo "CloudFront cache invalidated"
```

Rolling back means re-running the update step with an older `<sha>.zip` kept in the artifacts bucket (90 days).

- [ ] **Step 4: Rewrite `migrate.yml`, `seed.yml` and `delete-map.yml`**

Each keeps its `name`, `on`, `permissions` and the existing credentials step, drops the ECS `env` entries and replaces the task steps with one invocation step.

`migrate.yml` job steps after credentials:

```yaml
      - name: Checkout
        uses: actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803 # v6.1.0
        with:
          persist-credentials: false

      - name: Run migration
        run: scripts/invoke-lambda-task '{"task":"db:migrate"}'
```

(Put the checkout step before the credentials step, since the script lives in the repository; `env` keeps only `AWS_REGION`.)

`seed.yml`: same, with payload `'{"task":"db:seed"}'` and step name `Run seed`.

`delete-map.yml`: same shape; the ULID reaches the script through an environment variable so that it cannot break the JSON or the shell:

```yaml
      - name: Delete map
        run: scripts/invoke-lambda-task "$(jq -nc --arg ulid "$MAP_ULID" '{task: "maps:delete", map_ulid: $ulid}')"
        env:
          MAP_ULID: ${{ inputs.ulid }}
```

- [ ] **Step 5: Lint and commit**

Run: `bash -n scripts/invoke-lambda-task scripts/seed-db && bundle exec rake`
Expected: no shell errors; PASS. If `actionlint` is installed, run it on `.github/workflows`.

```bash
git add scripts .github/workflows
git commit -m ":construction_worker: Deploy and run one-off tasks through Lambda"
```

---

### Task 16: Documentation, Dockerfile and Renovate

**Files:**
- Delete: `Dockerfile`, `.dockerignore`
- Modify: `.github/renovate.json`, `doc/design/10-infrastructure.md`, `11-local-development.md`, `14-secrets-management.md`, `16-lambda-migration.md`, `AGENTS.md` (the design document table is unchanged; add row 16)

- [ ] **Step 1: Remove the Docker packaging**

```bash
git rm Dockerfile .dockerignore
```

- [ ] **Step 2: Renovate**

Add to `packageRules` in `.github/renovate.json`:

```json
    {
      "matchPackageNames": ["public.ecr.aws/lambda/ruby"],
      "matchUpdateTypes": ["major", "minor"],
      "enabled": false
    }
```

(The build script references the image by tag in a shell script, which Renovate does not scan by default; if a custom manager is added later this rule applies. Updating the Ruby minor version is manual: change the Terraform `lambda_runtime`, the script tag and CI together.)

- [ ] **Step 3: Update the design documents**

- `10-infrastructure.md`: rewrite the AWS services table (remove ECS Fargate, ECR, ALB, the ALB part of ACM; add Lambda, the NAT instance, the assets and artifacts buckets), the domains table (the application domain is served by the `app` distribution), the container deployment, CI/CD workflow and migration sections (point to `16-lambda-migration.md`), the CloudFront distributions section (Lambda and assets origins), and state that RDS shares the default VPC with the new private subnets. Correct the claim that RDS is in a private subnet.
- `11-local-development.md`: fix the process table entry to `bundle exec rake s3:process_queues`, and add a sentence that production runs this logic in Lambda.
- `14-secrets-management.md`: replace "ECS Injection" with the SSM loader description and note the origin verification secret exception.
- `16-lambda-migration.md`: change "Rolling back application code uses Lambda versions" to "Rolling back uses the package of an earlier commit kept in the artifacts bucket", remove "publish versions" from the deploy steps, and state that assets initially get `Cache-Control: public, max-age=86400` (a longer `immutable` lifetime for fingerprinted files can follow once the file name pattern is reliable).
- `AGENTS.md`: add `| 16 | [Lambda Migration](doc/design/16-lambda-migration.md) |` to the design documents table.

- [ ] **Step 4: Verify and commit**

Run: `bundle exec rake`
Expected: PASS. Re-read the changed documents together for contradictions (for example any remaining mention of ECS, ALB or ECR outside the migration document).

```bash
git add -A
git commit -m ":memo: Document the Lambda architecture and remove the Dockerfile"
```

---

### Task 17: Cutover

Every step below changes AWS or the public site; run each only after the user approves it, and report outputs back.

- [ ] **Step 1: Allow the CI role to use the new resources**

Inspect the role first (it is not managed in Terraform):

```bash
cd /Users/sakuro/github.com/sakuro/pasta_atlas && unset AWS_ENDPOINT_URL && export AWS_PROFILE=terraform
aws iam list-attached-role-policies --role-name github-actions-cicd
aws iam list-role-policies --role-name github-actions-cicd
```

Then add (as an inline policy named `lambda-deploy`) permissions for `lambda:UpdateFunctionCode`, `lambda:GetFunction`, `lambda:GetFunctionConfiguration`, `lambda:InvokeFunction` on the four `pasta-atlas-production-*` functions, `s3:PutObject` and `s3:ListBucket` on the artifacts and assets buckets, and keep the existing `cloudfront:ListDistributions` and `cloudfront:CreateInvalidation` rights. Use `aws iam put-role-policy --role-name github-actions-cicd --policy-name lambda-deploy --policy-document file://<policy.json>` with a policy document written to the scratchpad directory. Remove the ECS and ECR rights from the role once the old stack is gone.

- [ ] **Step 2: Clear the ECR repository**

```bash
IMAGES=$(aws ecr list-images --repository-name pasta-atlas-production --query 'imageIds[*]' --output json)
aws ecr batch-delete-image --repository-name pasta-atlas-production --image-ids "$IMAGES"
```

Expected: no failures. Terraform cannot delete a repository that still holds images.

- [ ] **Step 3: Check the SSM secrets**

```bash
for NAME in session_secret github_client_secret discord_client_secret steam_web_api_key database_url; do
  VALUE=$(aws ssm get-parameter --region ap-northeast-1 --name "/pasta-atlas/production/$NAME" --with-decryption --query Parameter.Value --output text)
  [ "$VALUE" = "REPLACE_WITH_ACTUAL_VALUE" ] && echo "$NAME: still a placeholder" || echo "$NAME: set"
done
```

Expected: all `set`. Any placeholder must be filled in with `aws ssm put-parameter --overwrite` (see `14-secrets-management.md`) before continuing; never print or log the values.

- [ ] **Step 4: Apply Terraform**

```bash
terraform -chdir=terraform/environments/production plan -input=false -out=/private/tmp/claude-501/lambda.tfplan
```

Show the plan summary to the user. It includes the pending CORS change on the `mapshots` bucket (`POST` and `PUT`, from commit `1e7d45f`), which presigned POST uploads need. After approval: `terraform -chdir=terraform/environments/production apply /private/tmp/claude-501/lambda.tfplan`. Keep `app_dns_enabled = false`, so the application domain does not resolve to the new distribution yet.

- [ ] **Step 5: Deploy the code**

Merge the branch to `main` after CI passes (ask the user), then run the `Deploy` workflow: `gh workflow run deploy.yml` and watch it with `gh run watch`. Expected: all four functions report `Updated`.

- [ ] **Step 6: Migrate**

Run `gh workflow run migrate.yml` and watch it. Expected: the log shows the migration output and the job succeeds. If it fails, read the CloudWatch log group `/aws/lambda/pasta-atlas-production-task`.

- [ ] **Step 7: Verify before publishing**

```bash
DOMAIN=$(terraform -chdir=terraform/environments/production output -raw app_cloudfront_domain_name)
curl -s -o /dev/null -w '%{http_code}\n' "https://$DOMAIN/up"
curl -s -o /dev/null -w '%{http_code}\n' "https://$DOMAIN/"
URL=$(aws lambda get-function-url-config --function-name pasta-atlas-production-app --query FunctionUrl --output text)
curl -s -o /dev/null -w '%{http_code}\n' "$URL"
```

Expected: `200`, `200`, and `403` for the direct Function URL (no secret header). Then check in the browser against `https://$DOMAIN/` what the CloudFront domain allows (OAuth callbacks need the real domain, so the login flow is verified after Step 8). Record the first-request latency for the design document's cold start item.

- [ ] **Step 8: Publish the domain**

Set `app_dns_enabled` to `true` (change the default in `variables.tf` and commit), run `terraform plan`, show the plan (one Gandi record to add), then apply after approval. Verify `https://pasta-atlas.layer8.works/` and a full sign-in with each OAuth provider, a map upload (presigned POST against the `mapshots` bucket, now with `POST` in CORS), and map viewing.

- [ ] **Step 9: Follow-ups**

Check Cost Explorer after a few days against the estimate in the design document. Open the separate guest cleanup removal issue (see the design document's Follow-ups) if the user asks for it.
