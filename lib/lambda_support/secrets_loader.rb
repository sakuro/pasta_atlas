# frozen_string_literal: true

module LambdaSupport
  # Lambda cannot inject SSM parameters into the environment the way ECS did, so
  # they are fetched once during initialization.
  class SecretsLoader
    class MissingParametersError < StandardError; end

    PARAMETERS = {
      "session_secret" => "SESSION_SECRET",
      "github_client_secret" => "GITHUB_CLIENT_SECRET",
      "discord_client_secret" => "DISCORD_CLIENT_SECRET",
      "steam_web_api_key" => "STEAM_WEB_API_KEY",
      "database_url" => "DATABASE_URL",
      "origin_verify_secret" => "ORIGIN_VERIFY_SECRET"
    }.freeze
    private_constant :PARAMETERS

    def initialize(ssm_client:, prefix:, env: ENV)
      @ssm_client = ssm_client
      @prefix = prefix
      @env = env
    end

    def call
      response = @ssm_client.get_parameters(names: PARAMETERS.keys.map {|name| "#{@prefix}/#{name}" }, with_decryption: true)
      raise MissingParametersError, "missing SSM parameters: #{response.invalid_parameters.join(", ")}" unless response.invalid_parameters.empty?

      response.parameters.each do |parameter|
        name = parameter.name.delete_prefix("#{@prefix}/")
        @env[PARAMETERS.fetch(name) { raise KeyError, "unexpected SSM parameter: #{parameter.name}" }] = parameter.value
      end
    end
  end
end
