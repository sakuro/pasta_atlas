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
      stub_parameters({"session_secret" => "s", "database_url" => "postgres://db", "origin_verify_secret" => "o"})

      loader.call

      expect(env).to eq("SESSION_SECRET" => "s", "DATABASE_URL" => "postgres://db", "ORIGIN_VERIFY_SECRET" => "o")
    end

    it "requests every known parameter with decryption" do
      requested = nil
      client.stub_responses(:get_parameters, ->(context) {
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

      expect { loader.call }.to raise_error(LambdaSupport::SecretsLoader::MissingParametersError, "missing SSM parameters: /pasta-atlas/production/database_url")
    end
  end
end
