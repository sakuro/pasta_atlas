# frozen_string_literal: true

# CloudFront does not cache the app today (Managed-CachingDisabled), but the responses carry the
# session cookie and per-session tokens, so they must also say so themselves to any other cache.
RSpec.describe "Cache-Control of action responses", :db, type: :request do
  let(:no_store) { "no-store, private" }

  it "is set on the HTML shell, which embeds the CSRF token" do
    header "Accept", "text/html"
    get "/"

    expect(last_response.headers["Cache-Control"]).to eq(no_store)
  end

  it "is set on a 404 page" do
    header "Accept", "text/html"
    get "/nonexistent"

    expect(last_response.status).to be(404)
    expect(last_response.headers["Cache-Control"]).to eq(no_store)
  end

  it "is set on a JSON response" do
    get "/api/v1/auth/current"

    expect(last_response.headers["Cache-Control"]).to eq(no_store)
  end

  it "is set on a halted error response" do
    header "Content-Type", "application/json"
    post "/api/v1/uploads", JSON.generate({metadata: {map_id: "abcd1234", unique_id: "abcd1234", tick: 100}, total_image_count: 3, name: "x"})

    expect(last_response.status).to be(403)
    expect(last_response.headers["Cache-Control"]).to eq(no_store)
  end

  it "is set on a redirect" do
    get "/auth/failure"

    expect(last_response.status).to be(302)
    expect(last_response.headers["Cache-Control"]).to eq(no_store)
  end

  it "is set on a response to a body that cannot be parsed" do
    header "Content-Type", "application/json"
    patch "/api/v1/uploads/unknown", "{not json"

    expect(last_response.status).to be(400)
    expect(last_response.headers["Cache-Control"]).to eq(no_store)
  end
end
