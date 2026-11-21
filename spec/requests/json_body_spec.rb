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

  it "still serves HTML pages to a browser" do
    header "Accept", "text/html"
    get "/about"

    expect(last_response.status).to be(200)
  end
end
