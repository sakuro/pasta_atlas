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
      private_constant :HEADER, :READINESS_PATH

      def initialize(app, secret:)
        # An empty secret would match requests that omit the header.
        raise ArgumentError, "secret must not be empty" if secret.empty?

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
