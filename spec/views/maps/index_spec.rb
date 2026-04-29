# frozen_string_literal: true

RSpec.describe PastaAtlas::Views::Maps::Index do
  let(:view) { PastaAtlas::Views::Maps::Index.new }

  let(:map_with_profile) { double("Map", user_id: 1, ulid: "01MAP1", display_name: "First Map") }
  let(:map_without_profile) { double("Map", user_id: 2, ulid: "01MAP2", display_name: "Second Map") }
  let(:profile) { double("UserProfile", name: "alice") }
  let(:profile2) { double("UserProfile", name: "bob") }

  def render(maps:, user_profiles_by_id:, page:, per_page:, total:)
    view.call(layout: false, maps:, user_profiles_by_id:, page:, per_page:, total:).to_s
  end

  it "renders a link for each map" do
    html = render(maps: [map_with_profile, map_without_profile], user_profiles_by_id: {1 => profile, 2 => profile2}, page: 1, per_page: 20, total: 2)

    expect(html).to include(
      %(<a href="/@alice/maps/01MAP1">First Map</a>),
      %(<a href="/@bob/maps/01MAP2">Second Map</a>)
    )
  end

  it "renders the user profile name when available" do
    html = render(maps: [map_with_profile], user_profiles_by_id: {1 => profile}, page: 1, per_page: 20, total: 1)

    expect(html).to include("alice")
  end

  it "renders no pagination when all maps fit on one page" do
    html = render(maps: [map_with_profile], user_profiles_by_id: {1 => profile}, page: 1, per_page: 20, total: 1)

    expect(html).not_to include("pagination-previous", "pagination-next")
  end

  it "renders a next link when more pages remain" do
    html = render(maps: [map_with_profile], user_profiles_by_id: {1 => profile}, page: 1, per_page: 1, total: 2)

    expect(html).to include("pagination-next")
    expect(html).not_to include("pagination-previous")
  end

  it "renders a previous link on pages after the first" do
    html = render(maps: [map_without_profile], user_profiles_by_id: {2 => profile2}, page: 2, per_page: 1, total: 2)

    expect(html).to include("pagination-previous")
    expect(html).not_to include("pagination-next")
  end
end
