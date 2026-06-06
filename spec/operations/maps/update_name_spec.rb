# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Maps::UpdateName do
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:operation) { PastaAtlas::Operations::Maps::UpdateName.new(map_repo:, user_repo:) }

  let(:user) { double("User", id: 1, can_rename_map?: true) }
  let(:map) { double("Map", id: 10, ulid: "01MAP1", user_id: 1, owned_by?: true) }
  let(:renamed_map) { double("Map", id: 10, display_name: "New Name") }

  before do
    allow(user_repo).to receive(:find_by_id).with(1).and_return(user)
    allow(map_repo).to receive(:find_by_ulid).with("01MAP1").and_return(map)
    allow(map).to receive(:owned_by?).with(user).and_return(true)
  end

  describe "#call" do
    context "when user is a guest" do
      let(:guest) { double("User", id: 2, can_rename_map?: false) }

      before { allow(user_repo).to receive(:find_by_id).with(2).and_return(guest) }

      it "returns failure with :forbidden" do
        result = operation.call(ulid: "01MAP1", name: "New Name", current_user_id: 2)

        expect(result).to be_failure
        expect(result.failure).to eq(:forbidden)
      end
    end

    context "when map is not found" do
      before { allow(map_repo).to receive(:find_by_ulid).with("NOTFOUND").and_return(nil) }

      it "returns failure with :not_found" do
        result = operation.call(ulid: "NOTFOUND", name: "New Name", current_user_id: 1)

        expect(result).to be_failure
        expect(result.failure).to eq(:not_found)
      end
    end

    context "when user does not own the map" do
      let(:other_map) { double("Map", id: 10, ulid: "01MAP1", user_id: 99, owned_by?: false) }

      before { allow(map_repo).to receive(:find_by_ulid).with("01MAP1").and_return(other_map) }

      it "returns failure with :forbidden" do
        result = operation.call(ulid: "01MAP1", name: "New Name", current_user_id: 1)

        expect(result).to be_failure
        expect(result.failure).to eq(:forbidden)
      end
    end

    context "when the name exceeds 30 grapheme clusters" do
      it "returns Failure([:invalid, message])" do
        result = operation.call(ulid: "01MAP1", name: "あ" * 31, current_user_id: 1)

        expect(result).to be_failure
        code, message = result.failure
        expect(code).to eq(:invalid)
        expect(message).to eq("error-map-name-too-long")
      end
    end

    context "when the name contains disallowed characters" do
      it "returns Failure([:invalid, message])" do
        result = operation.call(ulid: "01MAP1", name: "bad\tname", current_user_id: 1)

        expect(result).to be_failure
        code, message = result.failure
        expect(code).to eq(:invalid)
        expect(message).to eq("error-map-name-invalid-chars")
      end
    end

    context "when the name is valid" do
      before do
        allow(map_repo).to receive(:update_name).with(id: 10, name: "New Name")
        allow(map_repo).to receive(:find_by_id).with(10).and_return(renamed_map)
      end

      it "renames the map and returns it" do
        result = operation.call(ulid: "01MAP1", name: "New Name", current_user_id: 1)

        expect(result).to be_success
        expect(result.value!).to eq(renamed_map)
        expect(map_repo).to have_received(:update_name).with(id: 10, name: "New Name")
      end
    end
  end
end
