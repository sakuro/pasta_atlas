# frozen_string_literal: true

RSpec.describe PastaAtlas::Views::Maps::Index do
  let(:view) { PastaAtlas::Views::Maps::Index.new }

  let(:alice_map) { double("Map", user_id: 1, ulid: "01MAP1", display_name: "First Map") }
  let(:bob_map) { double("Map", user_id: 2, ulid: "01MAP2", display_name: "Second Map") }
  let(:alice) { double("User", id: 1, name: "alice") }
  let(:bob) { double("User", id: 2, name: "bob") }
  let(:alice_profile) { double("UserProfile", display_name: "Alice") }
  let(:bob_profile) { double("UserProfile", display_name: "Bob") }

  def render(maps:, users_by_id:, profiles_by_user_id:, page:, per_page:, total:, thumbnail_urls_by_map_ulid: {}, avatar_urls_by_user_id: {}, metadata_urls_by_map_ulid: {})
    view.call(layout: false, maps:, users_by_id:, profiles_by_user_id:, avatar_urls_by_user_id:, thumbnail_urls_by_map_ulid:, metadata_urls_by_map_ulid:, page:, per_page:, total:).to_s
  end

  it "renders a link for each map" do
    html = render(maps: [alice_map, bob_map], users_by_id: {1 => alice, 2 => bob}, profiles_by_user_id: {1 => alice_profile, 2 => bob_profile}, page: 1, per_page: 20, total: 2)

    expect(html).to include(
      %(<a href="/@alice/maps/01MAP1">First Map</a>),
      %(<a href="/@bob/maps/01MAP2">Second Map</a>)
    )
  end

  it "renders the user display name with a profile link" do
    html = render(maps: [alice_map], users_by_id: {1 => alice}, profiles_by_user_id: {1 => alice_profile}, page: 1, per_page: 20, total: 1)

    expect(html).to include('href="/@alice/profile"', "Alice")
  end

  it "renders no pagination when all maps fit on one page" do
    html = render(maps: [alice_map], users_by_id: {1 => alice}, profiles_by_user_id: {1 => alice_profile}, page: 1, per_page: 20, total: 1)

    expect(html).not_to include("pagination-previous", "pagination-next")
  end

  it "renders a next link when more pages remain" do
    html = render(maps: [alice_map], users_by_id: {1 => alice}, profiles_by_user_id: {1 => alice_profile}, page: 1, per_page: 1, total: 2)

    expect(html).to include("pagination-next")
    expect(html).not_to include("pagination-previous")
  end

  it "renders a previous link on pages after the first" do
    html = render(maps: [bob_map], users_by_id: {2 => bob}, profiles_by_user_id: {2 => bob_profile}, page: 2, per_page: 1, total: 2)

    expect(html).to include("pagination-previous")
    expect(html).not_to include("pagination-next")
  end
end
