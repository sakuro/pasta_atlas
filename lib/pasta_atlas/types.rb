# frozen_string_literal: true

require "dry/types"
require "uri"

module PastaAtlas
  Types = Dry.Types(default: :strict)
  public_constant :Types

  module Types
    # An absolute http(s) URL. URI::HTTPS is a subclass of URI::HTTP, so this accepts both.
    HTTPURL = Constructor(URI::HTTP) {|value|
      # URI.parse accepts "https://" and returns an empty host, so the host is checked for emptiness.
      uri = begin
        URI.parse(value.to_s)
      rescue URI::InvalidURIError
        nil
      end
      raise Dry::Types::CoercionError, "must be an http(s) URL with a host: #{value.inspect}" unless uri.is_a?(URI::HTTP) && !uri.host.to_s.empty?

      uri
    }
    public_constant :HTTPURL

    HTTPSURL = HTTPURL.constrained(type: URI::HTTPS)
    public_constant :HTTPSURL

    def self.base_url(uri)
      # Object keys are appended to the base URL as "#{base_url}/#{key}", so it must not end with a
      # slash and must not carry a query or a fragment.
      return uri unless uri.query || uri.fragment || uri.path.end_with?("/")

      raise Dry::Types::CoercionError, "must not end with a slash or have a query or a fragment: #{uri}"
    end
    private_class_method :base_url

    # The URL under which the objects of the mapshots bucket are served by CloudFront.
    CloudFrontBaseURL = Constructor(URI::HTTPS) {|value|
      # A Constructor wrapping HTTPSURL would run before its coercion and see the raw input, so
      # the value is coerced first and base_url receives a URI.
      base_url(HTTPSURL[value])
    }
    public_constant :CloudFrontBaseURL

    # Development and test serve the objects from Floci, which is plain HTTP and addresses the
    # bucket by path (http://localhost:4566/bucket).
    LocalCloudFrontBaseURL = Constructor(URI::HTTP) {|value| base_url(HTTPURL[value]) }
    public_constant :LocalCloudFrontBaseURL
  end
end
