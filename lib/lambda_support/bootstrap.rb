# frozen_string_literal: true

module LambdaSupport
  # Hanami reads its settings while the app class is evaluated, so secrets have to
  # be in ENV before it loads.
  module Bootstrap
    def self.load_secrets(env: ENV)
      prefix = env.fetch("SSM_PARAMETER_PREFIX", nil)
      # Outside Lambda SSM_PARAMETER_PREFIX is unset and nothing happens.
      return unless prefix

      require "aws-sdk-ssm"
      require_relative "secrets_loader"
      SecretsLoader.new(ssm_client: Aws::SSM::Client.new, prefix:, env:).call
    end
  end
end
