# frozen_string_literal: true

# omniauth-steam decodes the Steam Web API response with MultiJson. multi_json 1.21.1 passed its
# options to JSON.parse positionally, which json 3 rejects, and every Steam sign-in failed.
RSpec.describe MultiJSON do
  it "parses a document with the installed json gem" do
    expect(MultiJSON.parse('{"response": {"players": []}}')).to eq("response" => {"players" => []})
  end
end
