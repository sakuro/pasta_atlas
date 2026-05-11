# frozen_string_literal: true

RSpec.describe PastaAtlas::Views::Maps::Index do
  let(:view) { PastaAtlas::Views::Maps::Index.new }

  let(:alice_info) { PastaAtlas::Values::UserInfo[name: "alice", display_name: "Alice", avatar_url: nil] }
  let(:bob_info) { PastaAtlas::Values::UserInfo[name: "bob", display_name: "Bob", avatar_url: nil] }
  let(:alice_map_info) { PastaAtlas::Values::MapInfo[ulid: "01MAP1", display_name: "First Map", user_info: alice_info, thumbnail_url: nil, metadata_url: nil, updated_at: nil] }
  let(:bob_map_info) { PastaAtlas::Values::MapInfo[ulid: "01MAP2", display_name: "Second Map", user_info: bob_info, thumbnail_url: nil, metadata_url: nil, updated_at: nil] }

  def render(map_infos:, page:, per_page:, total:)
    view.call(layout: false, map_infos:, page:, per_page:, total:).to_s
  end

  it "renders a link for each map" do
    html = render(map_infos: [alice_map_info, bob_map_info], page: 1, per_page: 20, total: 2)

    expect(html).to include(
      %(<a href="/@alice/maps/01MAP1">First Map</a>),
      %(<a href="/@bob/maps/01MAP2">Second Map</a>)
    )
  end

  it "renders the user display name with a profile link" do
    html = render(map_infos: [alice_map_info], page: 1, per_page: 20, total: 1)

    expect(html).to include('href="/@alice"', "Alice")
  end

  it "renders no pagination when all maps fit on one page" do
    html = render(map_infos: [alice_map_info], page: 1, per_page: 20, total: 1)

    expect(html).not_to include("pagination-previous", "pagination-next")
  end

  it "renders a next link when more pages remain" do
    html = render(map_infos: [alice_map_info], page: 1, per_page: 1, total: 2)

    expect(html).to include("pagination-next")
    expect(html).not_to include("pagination-previous")
  end

  it "renders a previous link on pages after the first" do
    html = render(map_infos: [bob_map_info], page: 2, per_page: 1, total: 2)

    expect(html).to include("pagination-previous")
    expect(html).not_to include("pagination-next")
  end
end
