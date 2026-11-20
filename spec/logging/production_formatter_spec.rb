# frozen_string_literal: true

require "stringio"

RSpec.describe PastaAtlas::Logging::ProductionFormatter do
  let(:stream) { StringIO.new }
  let(:logger) { Dry.Logger(:test, stream:, formatter: PastaAtlas::Logging::ProductionFormatter) }

  def entry
    JSON.parse(stream.string.lines.last)
  end

  it "drops the request parameters" do
    logger.info(verb: "POST", status: 201, path: "/api/v1/uploads", params: {metadata: {seed: 1}})

    expect(entry).not_to have_key("params")
  end

  it "keeps the other fields of the entry" do
    logger.info(verb: "POST", status: 201, client: "client-address", path: "/api/v1/uploads", params: {})

    expect(entry).to include("verb" => "POST", "status" => 201, "client" => "client-address", "path" => "/api/v1/uploads", "severity" => "INFO")
  end
end
