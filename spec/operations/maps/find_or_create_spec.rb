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

      it "keeps the name of a map that has one when the user may not rename" do
        existing_map = Factory[:map, user:, mapshot_map_id: "named", name: "First"]

        result = operation.call(user_id: user.id, mapshot_map_id: "named", name: "Second", update_name_on_conflict: false)

        expect(result.value!).to have_attributes(id: existing_map.id, name: "First")
      end

      it "sets the name of a map that has none even when the user may not rename" do
        result = operation.call(user_id: user.id, mapshot_map_id: "abc123", name: "Given", update_name_on_conflict: false)

        expect(result.value!.name).to eq("Given")
      end

      it "keeps the savename of the first upload" do
        operation.call(user_id: user.id, mapshot_map_id: "saved", savename: "first")

        result = operation.call(user_id: user.id, mapshot_map_id: "saved", savename: "second")

        expect(result.value!.savename).to eq("first")
      end

      it "does not overwrite name when not provided" do
        result = operation.call(user_id: user.id, mapshot_map_id: "abc123")

        expect(result).to be_success
        expect(result.value!.name).to be_nil
      end
    end
  end
end
