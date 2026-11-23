# frozen_string_literal: true

require "rack/mock"

# In production Hanami answers an unhandled exception from public/500.html (config.render_errors).
# The test environment does not render errors, so the middleware is built here as the app builds it.
RSpec.describe "Error pages" do
  let(:failing_app) { ->(_env) { raise StandardError, "boom" } }
  let(:errors_app) { Hanami::Middleware::PublicErrorsApp.new(Hanami.app.root.join("public")) }
  # Hanami::Config defines its settings dynamically, so a verifying double cannot stand in for it.
  let(:config) do
    Data.define(:render_errors, :render_error_responses)[render_errors: true, render_error_responses: Hanami.app.config.render_error_responses]
  end
  let(:middleware) { Hanami::Middleware::RenderErrors.new(failing_app, config, errors_app) }

  def get(accept)
    status, headers, body = middleware.call(Rack::MockRequest.env_for("/maps", "HTTP_ACCEPT" => accept))
    [status, headers, body.join]
  end

  it "answers an unhandled exception with public/500.html and status 500" do
    status, headers, body = get("text/html")

    expect(status).to eq(500)
    expect(headers["Content-Type"]).to eq("text/html; charset=utf-8")
    expect(body).to eq(Hanami.app.root.join("public/500.html").read)
  end

  it "answers a JSON request with a JSON body instead of the page" do
    status, _headers, body = get("application/json")

    expect(status).to eq(500)
    expect(JSON.parse(body)).to eq("status" => 500, "error" => "Internal Server Error")
  end
end
