# frozen_string_literal: true

require "uri"

RSpec.describe OpenID::StandardFetcher do
  it "verifies the server certificate of https requests" do
    connection = OpenID.fetcher.make_connection(URI("https://steamcommunity.com/openid"))

    expect(connection.verify_mode).to eq(OpenSSL::SSL::VERIFY_PEER)
  end

  it "trusts the CA bundle of the system" do
    expect(File).to exist(OpenID.fetcher.ca_file)
  end
end
