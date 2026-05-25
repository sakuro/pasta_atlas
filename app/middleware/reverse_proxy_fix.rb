# frozen_string_literal: true

# auto_register: false

require "uri"

module PastaAtlas
  module Middleware
    # Corrects rack.url_scheme and HTTP_HOST when running behind a reverse proxy
    # (CloudFront → ALB → ECS) that uses HTTP internally.
    # Without this, Rack::OpenID's return_to verification fails because req.url
    # reflects the internal HTTP scheme and ALB hostname instead of the public HTTPS URL.
    class ReverseProxyFix
      def initialize(app, base_url:)
        @app = app
        uri = URI.parse(base_url)
        @scheme = uri.scheme
        default_port = @scheme == "https" ? 443 : 80
        @host = uri.port == default_port ? uri.host : "#{uri.host}:#{uri.port}"
      end

      def call(env)
        env["rack.url_scheme"] = @scheme
        env["HTTPS"] = "on" if @scheme == "https"
        env["HTTP_HOST"] = @host
        @app.call(env)
      end
    end
  end
end
