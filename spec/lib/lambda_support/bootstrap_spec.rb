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
