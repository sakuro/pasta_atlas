# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Maps::FindOrCreate, :db do
  let(:operation) { Hanami.app["operations.maps.find_or_create"] }
  let(:user) { Factory[:user] }

  describe "#call" do
    context "when no map exists for the user and mapshot_map_id" do
      it "creates the map with the display name" do
        result = operation.call(user_id: user.id, mapshot_map_id: "abc123", display_name: "My Map")

        expect(result).to be_success
        expect(result.value!).to have_attributes(user_id: user.id, mapshot_map_id: "abc123", display_name: "My Map")
      end
    end

    context "when a map already exists" do
      let!(:existing_map) { Factory[:map, user:, mapshot_map_id: "abc123", display_name: "First"] }

      it "returns the existing map without creating a duplicate" do
        result = operation.call(user_id: user.id, mapshot_map_id: "abc123", display_name: "First")

        expect(result).to be_success
        expect(result.value!.id).to eq(existing_map.id)
      end

      it "replaces the display name" do
        result = operation.call(user_id: user.id, mapshot_map_id: "abc123", display_name: "Second")

        expect(result.value!).to have_attributes(id: existing_map.id, display_name: "Second")
      end

      it "keeps the display name when the user may not rename" do
        result = operation.call(user_id: user.id, mapshot_map_id: "abc123", display_name: "Second", update_display_name_on_conflict: false)

        expect(result.value!).to have_attributes(id: existing_map.id, display_name: "First")
      end
    end
  end
end
