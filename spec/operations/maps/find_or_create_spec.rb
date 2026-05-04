# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Maps::FindOrCreate, :db do
  let(:operation) { Hanami.app["operations.maps.find_or_create"] }
  let(:user) { Factory[:user] }

  describe "#call" do
    context "when no map exists for the user and mapshot_map_id" do
      it "creates and returns the map" do
        result = operation.call(user_id: user.id, mapshot_map_id: "abc123")

        expect(result).to be_success
        map = result.value!
        expect(map.user_id).to eq(user.id)
        expect(map.mapshot_map_id).to eq("abc123")
      end

      it "sets name when provided" do
        result = operation.call(user_id: user.id, mapshot_map_id: "abc123", name: "My Map")

        expect(result).to be_success
        expect(result.value!.name).to eq("My Map")
      end
    end

    context "when a map already exists" do
      let!(:existing_map) { Factory[:map, user:, mapshot_map_id: "abc123", name: nil] }

      it "returns the existing map without creating a duplicate" do
        result = operation.call(user_id: user.id, mapshot_map_id: "abc123")

        expect(result).to be_success
        expect(result.value!.id).to eq(existing_map.id)
      end

      it "updates name when provided" do
        result = operation.call(user_id: user.id, mapshot_map_id: "abc123", name: "Updated Name")

        expect(result).to be_success
        expect(result.value!.name).to eq("Updated Name")
      end

      it "does not overwrite name when not provided" do
        result = operation.call(user_id: user.id, mapshot_map_id: "abc123")

        expect(result).to be_success
        expect(result.value!.name).to be_nil
      end
    end
  end
end
