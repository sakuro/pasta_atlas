# frozen_string_literal: true

RSpec.describe "Root", :db, type: :request do
  it "returns 200" do
    get "/"

    expect(last_response.status).to be(200)
  end
end
