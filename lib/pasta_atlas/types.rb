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
  end
end
