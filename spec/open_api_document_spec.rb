# frozen_string_literal: true

require "hanami/router/inspector"

RSpec.describe OpenAPIDocument do
  describe "#response_errors" do
    let(:document) { OpenAPIDocument.new(SPEC_ROOT.join("fixtures/openapi.yaml")) }
    let(:operation) { "GET /things/{id}" }

    def errors_for(status, body: "", content_type: "application/json", operation: self.operation)
      document.response_errors(operation, status:, content_type:, body:)
    end

    it "accepts a body that matches the schema" do
      expect(errors_for(200, body: '{"id":"1"}', content_type: "application/json; charset=utf-8")).to eq([])
    end

    it "reports a body that does not match the schema" do
      expect(errors_for(200, body: '{"id":1,"extra":true}')).to contain_exactly(
        a_string_including("`/id` is not a string"),
        a_string_including("`/extra` is a disallowed additional property")
      )
    end

    it "reports a body that is not JSON" do
      expect(errors_for(200, body: "Not Found")).to contain_exactly(a_string_starting_with("body is not valid JSON"))
    end

    it "reports a content type other than application/json" do
      expect(errors_for(200, body: '{"id":"1"}', content_type: "text/plain")).to eq(['expected application/json, got "text/plain"'])
    end

    it "checks only the status of a response documented without content" do
      expect(errors_for(404, body: "Not Found", content_type: "text/plain")).to eq([])
    end

    it "reports an operation that is not documented" do
      expect(errors_for(200, operation: "POST /things/{id}")).to eq(["POST /things/{id} is not documented"])
    end

    it "reports a status that is not documented" do
      expect(errors_for(401)).to eq(["GET /things/{id} does not document status 401"])
    end

    it "rejects a $ref'd response" do
      expect(errors_for(409)).to eq(["GET /things/{id} uses $ref for status 409, which is not supported"])
    end

    it "rejects a response without application/json content" do
      expect(errors_for(415)).to eq(["GET /things/{id} documents no application/json content for status 415"])
    end

    it "rejects an unquoted status key" do
      expect(errors_for(500)).to eq(["GET /things/{id} has the unquoted status key 500"])
    end
  end

  describe "the document of the repository" do
    let(:document) { OpenAPIDocument.default }

    # Operations not moved from doc/architecture/api.md yet. Remove an entry when it is added to openapi.yaml.
    let(:pending_operations) do
      [
        "GET /api/v1/auth/current",
        "GET /api/v1/auth/registration",
        "GET /api/v1/pages/{slug}",
        "POST /auth/register"
      ]
    end

    # Built from the route definitions, because Hanami.app.router is memoized without an inspector.
    # POST /auth/register is the only JSON route outside /api; the other /auth routes redirect.
    let(:json_operations) do
      inspector = Hanami::Router::Inspector.new(formatter: ->(routes) { routes })
      Hanami::Router.new(inspector:, resolver: ->(_path, to) { to }, &Hanami.app.routes)
      inspector.call.filter_map {|route|
        next if route.head?

        operation = "#{route.http_method} #{route.path.gsub(/:(\w+)/, "{\\1}")}"
        operation if operation.include?(" /api/") || operation == "POST /auth/register"
      }
    end

    it "is a valid OpenAPI document" do
      expect(document.document_errors).to eq([])
    end

    it "documents every JSON route that is not pending" do
      expect(document.operations).to match_array(json_operations - pending_operations)
    end

    it "lists only existing routes as pending" do
      expect(pending_operations - json_operations).to eq([])
    end
  end
end
