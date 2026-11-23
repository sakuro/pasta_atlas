# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Maps::Show do
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:generation_repo) { instance_double(PastaAtlas::Repos::GenerationRepo) }
  let(:settings) { double("Settings", cloudfront_base_url: "https://cdn.example.com") }
  let(:operation) { PastaAtlas::Operations::Maps::Show.new(map_repo:, user_repo:, user_profile_repo:, generation_repo:, settings:) }

  let(:map) { double("Map", id: 1, ulid: "01MAP1", display_name: "Test Map", user_id: 1) }
  let(:user) { double("User", id: 1, name: "alice") }
  let(:profile) { double("UserProfile", display_name: "Alice", avatar_s3_key: nil) }
  let(:completed_at) { Time.now }
  let(:generation) { double("Generation", ulid: "01GEN1", tick: 100, upload: double("Upload", completed_at:)) }
  let(:generations) { [generation] }

  describe "#call" do
    context "when map is found" do
      before do
        allow(map_repo).to receive(:find_by_ulid).with("01MAP1").and_return(map)
        allow(user_repo).to receive(:find_by_id!).with(1).and_return(user)
        allow(user_profile_repo).to receive(:find_by_user_id!).with(1).and_return(profile)
        allow(generation_repo).to receive(:find_complete_by_map_id).with(1).and_return(generations)
        allow(generation).to receive(:metadata_url).with("https://cdn.example.com").and_return("https://cdn.example.com/alice/map1/gen1/mapshot.json")
      end

      it "returns success with the map, its owner and its generations" do
        result = operation.call(ulid: "01MAP1")

        expect(result).to be_success
        payload = result.value!
        expect(payload[:map]).to eq(map)
        expect(payload[:updated_at]).to eq(completed_at)
        owner = payload[:owner]
        expect(owner).to be_a(PastaAtlas::Values::UserInfo)
        expect(owner.name).to eq("alice")
        expect(owner.display_name).to eq("Alice")
        expect(owner.avatar_url).to be_nil
        expect(payload[:generations]).to eq([{ulid: "01GEN1", tick: 100, metadata_url: "https://cdn.example.com/alice/map1/gen1/mapshot.json"}])
      end

      context "when an older save was uploaded after a newer one" do
        let(:older_save_completed_at) { completed_at + 60 }
        let(:older_save) { double("Generation", ulid: "01GEN0", tick: 50, upload: double("Upload", completed_at: older_save_completed_at)) }
        let(:generations) { [generation, older_save] }

        before do
          allow(older_save).to receive(:metadata_url).with("https://cdn.example.com").and_return("https://cdn.example.com/alice/map1/gen0/mapshot.json")
        end

        it "keeps the highest tick first and takes updated_at from the last completed upload" do
          payload = operation.call(ulid: "01MAP1").value!

          expect(payload[:generations].map {|g| g[:ulid] }).to eq(%w[01GEN1 01GEN0])
          expect(payload[:updated_at]).to eq(older_save_completed_at)
        end
      end

      context "when profile has no display name" do
        let(:profile) { double("UserProfile", display_name: nil, avatar_s3_key: nil) }

        it "falls back to user name in the owner" do
          result = operation.call(ulid: "01MAP1")

          expect(result.value![:owner].display_name).to eq("alice")
        end
      end

      context "when profile has an avatar" do
        let(:profile) { double("UserProfile", display_name: "Alice", avatar_s3_key: "avatars/42/abc.jpg") }

        it "resolves avatar_url in the owner" do
          result = operation.call(ulid: "01MAP1")

          expect(result.value![:owner].avatar_url).to eq("https://cdn.example.com/avatars/42/abc.jpg")
        end
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

    context "when the map has no complete generation" do
      before do
        allow(map_repo).to receive(:find_by_ulid).with("01MAP1").and_return(map)
        allow(user_repo).to receive(:find_by_id!).with(1).and_return(user)
        allow(user_profile_repo).to receive(:find_by_user_id!).with(1).and_return(profile)
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
