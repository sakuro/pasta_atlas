# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Maps::Show do
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:generation_repo) { instance_double(PastaAtlas::Repos::GenerationRepo) }
  let(:operation) { PastaAtlas::Operations::Maps::Show.new(map_repo:, user_repo:, user_profile_repo:, generation_repo:) }

  let(:map) { double("Map", id: 1, ulid: "01MAP1", user_id: 1) }
  let(:user) { double("User", id: 1, name: "alice") }
  let(:profile) { double("UserProfile", display_name: "Alice", avatar_s3_key: nil) }
  let(:generations) { [double("Generation", tick: 100)] }

  describe "#call" do
    context "when map is found" do
      before do
        allow(map_repo).to receive(:find_by_ulid).with("01MAP1").and_return(map)
        allow(user_repo).to receive(:find_by_id).with(1).and_return(user)
        allow(user_profile_repo).to receive(:find_by_user_id).with(1).and_return(profile)
        allow(generation_repo).to receive(:find_complete_by_map_id).with(1).and_return(generations)
      end

      it "returns success with map, user, profile, and generations" do
        result = operation.call(ulid: "01MAP1")

        expect(result).to be_success
        payload = result.value!
        expect(payload[:map]).to eq(map)
        expect(payload[:user]).to eq(user)
        expect(payload[:profile]).to eq(profile)
        expect(payload[:generations]).to eq(generations)
      end
    end

    context "when map is not found" do
      before do
        allow(map_repo).to receive(:find_by_ulid).with("NOTFOUND").and_return(nil)
      end

      it "returns failure with :not_found" do
        result = operation.call(ulid: "NOTFOUND")

        expect(result).to be_failure
        expect(result.failure).to eq(:not_found)
      end
    end

    context "when all generations have expired" do
      before do
        allow(map_repo).to receive(:find_by_ulid).with("01MAP1").and_return(map)
        allow(user_repo).to receive(:find_by_id).with(1).and_return(user)
        allow(user_profile_repo).to receive(:find_by_user_id).with(1).and_return(profile)
        allow(generation_repo).to receive(:find_complete_by_map_id).with(1).and_return([])
      end

      it "returns failure with :not_found" do
        result = operation.call(ulid: "01MAP1")

        expect(result).to be_failure
        expect(result.failure).to eq(:not_found)
      end
    end
  end
end
