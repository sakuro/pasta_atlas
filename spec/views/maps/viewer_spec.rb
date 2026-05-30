# frozen_string_literal: true

RSpec.describe PastaAtlas::Views::Maps::Viewer do
  let(:view) { PastaAtlas::Views::Maps::Viewer.new }

  let(:author_info) { PastaAtlas::Values::UserInfo[name: "alice", display_name: "Alice", avatar_url: nil] }
  let(:context_class) do
    Class.new(PastaAtlas::Views::Context) do
      def viewer_relative_timestamps? = false
    end
  end
  let(:html) { view.call(layout: false, context: context_class.new, ulid: "01MAP", display_name: "My Save", author_info:).to_s }

  it "renders the display name as the page title" do
    expect(html).to include("My Save")
  end

  it "renders the map viewer element with the correct ulid" do
    expect(html).to include('data-ulid="01MAP"')
  end
end
