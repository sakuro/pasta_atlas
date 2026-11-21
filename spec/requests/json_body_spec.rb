# frozen_string_literal: true

# Hanami Action parses a request body only for the formats the app accepts, so a regression
# in config.actions.formats would silently drop the JSON bodies the frontend sends.
RSpec.describe "JSON request bodies", :db, type: :request do
  it "passes the parsed body to the action params" do
    header "Content-Type", "application/json"
    patch "/api/v1/uploads/unknown", JSON.generate({status: "complete"})

    # A body that was not parsed fails the params validation with 400 before the lookup.
    expect(last_response.status).to be(404)
  end

  it "validates the nested keys of a JSON body" do
    header "Content-Type", "application/json"
    post "/api/v1/uploads", JSON.generate({metadata: {map_id: "abcd1234", unique_id: "abcd1234", tick: 100}, total_image_count: 3, name: "x"})

    # A guest is rejected with 403 only after the params validation has passed.
    expect(last_response.status).to be(403)
  end

  it "rejects a body that is not valid JSON with 400" do
    header "Content-Type", "application/json"
    patch "/api/v1/uploads/unknown", "{not json"

    expect(last_response.status).to be(400)
  end

  it "rejects a body with a duplicate key with 400, as json 3 does" do
    header "Content-Type", "application/json"
    patch "/api/v1/uploads/unknown", '{"status":"complete","status":"failed"}'

    expect(last_response.status).to be(400)
  end

  it "still serves HTML pages to a browser" do
    header "Accept", "text/html"
    get "/about"

    expect(last_response.status).to be(200)
  end
end
