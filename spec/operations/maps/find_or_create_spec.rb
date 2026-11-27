# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Maps::FindOrCreate, :db do
  let(:operation) { Hanami.app["operations.maps.find_or_create"] }
  let(:user) { Factory[:user] }

  describe "#call" do
    context "when no map exists for the user and mapshot_map_id" do
      it "creates the map with the name" do
        result = operation.call(user_id: user.id, mapshot_map_id: "abc123", name: "My Map")

        expect(result).to be_success
        expect(result.value!).to have_attributes(user_id: user.id, mapshot_map_id: "abc123", name: "My Map")
      end
    end

    context "when a map already exists" do
      let!(:existing_map) { Factory[:map, user:, mapshot_map_id: "abc123", name: "First"] }

      it "returns the existing map without creating a duplicate" do
        result = operation.call(user_id: user.id, mapshot_map_id: "abc123", name: "First")

        expect(result).to be_success
        expect(result.value!.id).to eq(existing_map.id)
      end

      it "replaces the name" do
        result = operation.call(user_id: user.id, mapshot_map_id: "abc123", name: "Second")

        expect(result.value!).to have_attributes(id: existing_map.id, name: "Second")
      end

      it "keeps the name when the user may not rename" do
        result = operation.call(user_id: user.id, mapshot_map_id: "abc123", name: "Second", update_name_on_conflict: false)

        expect(result.value!).to have_attributes(id: existing_map.id, name: "First")
      end
    end
  end
end
