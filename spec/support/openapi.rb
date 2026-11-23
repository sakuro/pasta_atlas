# frozen_string_literal: true

require "json"
require "json_schemer"
require "uri"
require "yaml"

class OpenAPIDocument
  HTTP_METHODS = %w[get put post delete options head patch trace].freeze
  private_constant :HTTP_METHODS

  JSON_MEDIA_TYPE = "application/json"
  private_constant :JSON_MEDIA_TYPE

  def self.default = DEFAULT

  def initialize(path)
    @raw = YAML.safe_load_file(path).freeze
    @schemer = JSONSchemer.openapi(@raw)
  end

  def document_errors = @schemer.validate.map {|error| error["error"] }

  def operations
    @raw["paths"].flat_map {|path, item|
      (item.keys & HTTP_METHODS).map {|method| "#{method.upcase} #{path}" }
    }
  end

  # Returns the error messages for a response of the operation, e.g. "GET /api/v1/maps/{ulid}".
  # A response documented without content is checked for its status only.
  def response_errors(operation, status:, content_type:, body:)
    method, path = operation.split(" ", 2)
    responses = @raw.dig("paths", path, method.downcase, "responses")
    return ["#{operation} is not documented"] unless responses

    response = responses[status.to_s]
    unsupported = unsupported_response(responses, response, status)
    return ["#{operation} #{unsupported}"] if unsupported
    return [] unless response.key?("content")

    body_errors(json_pointer("paths", path, method.downcase, "responses", status.to_s, "content", JSON_MEDIA_TYPE, "schema"), content_type, body)
  end

  private def unsupported_response(responses, response, status)
    # YAML reads an unquoted 200 as an Integer key, which the lookup by string misses.
    if responses.key?(status)
      "has the unquoted status key #{status}"
    elsif response.nil?
      "does not document status #{status}"
    # A $ref'd response has no content of its own here and would pass unchecked.
    elsif response.key?("$ref")
      "uses $ref for status #{status}, which is not supported"
    elsif response.key?("content") && !response["content"].key?(JSON_MEDIA_TYPE)
      "documents no #{JSON_MEDIA_TYPE} content for status #{status}"
    end
  end

  private def body_errors(schema_pointer, content_type, body)
    media_type = content_type.to_s.split(";").first.to_s.strip
    return ["expected #{JSON_MEDIA_TYPE}, got #{content_type.inspect}"] unless media_type == JSON_MEDIA_TYPE

    @schemer.ref(schema_pointer).validate(JSON.parse(body)).map {|error| error["error"] }
  rescue JSON::ParserError => e
    ["body is not valid JSON: #{e.message}"]
  end

  # The fragment is parsed as a URI, so characters such as "{" must be percent-encoded.
  private def json_pointer(*tokens) = "#/#{tokens.map {|token| URI.encode_uri_component(token.gsub("~", "~0").gsub("/", "~1")) }.join("/")}"

  # Last in the class body, because new needs the methods above.
  DEFAULT = new(SPEC_ROOT.parent.join("openapi.yaml"))
  private_constant :DEFAULT
end

RSpec::Matchers.define :conform_to_openapi do |operation|
  match do |response|
    @errors = OpenAPIDocument.default.response_errors(
      operation,
      status: response.status,
      content_type: response.headers["Content-Type"],
      body: response.body.join
    )
    @errors.empty?
  end

  failure_message do |response|
    ["expected the #{response.status} response to conform to #{operation} in openapi.yaml:", *@errors.map {|error| "  #{error}" }].join("\n")
  end
end
