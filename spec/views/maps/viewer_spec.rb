# frozen_string_literal: true

RSpec.describe PastaAtlas::Views::Maps::Viewer do
  let(:view) { PastaAtlas::Views::Maps::Viewer.new }

  let(:author_info) { PastaAtlas::Values::UserInfo[name: "alice", display_name: "Alice", avatar_url: nil] }
  let(:html) { view.call(layout: false, ulid: "01MAP", display_name: "My Save", author_info:, relative_timestamps: false).to_s }

  it "renders the display name as the page title" do
    expect(html).to include("My Save")
  end

  it "renders the map viewer element with the correct ulid" do
    expect(html).to include('data-ulid="01MAP"')
  end
end
