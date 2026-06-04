# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Maps::Show do
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:generation_repo) { instance_double(PastaAtlas::Repos::GenerationRepo) }
  let(:settings) { double("Settings", cloudfront_base_url: "https://cdn.example.com") }
  let(:operation) { PastaAtlas::Operations::Maps::Show.new(map_repo:, user_repo:, user_profile_repo:, generation_repo:, settings:) }

  let(:map) { double("Map", id: 1, ulid: "01MAP1", user_id: 1) }
  let(:user) { double("User", id: 1, name: "alice") }
  let(:profile) { double("UserProfile", display_name: "Alice", avatar_s3_key: nil) }
  let(:generation_time) { Time.now }
  let(:generation) { double("Generation", ulid: "01GEN1", tick: 100, created_at: generation_time) }
  let(:generations) { [generation] }

  describe "#call" do
    context "when map is found" do
      before do
        allow(map_repo).to receive(:find_by_ulid).with("01MAP1").and_return(map)
        allow(user_repo).to receive(:find_by_id).with(1).and_return(user)
        allow(user_profile_repo).to receive(:find_by_user_id).with(1).and_return(profile)
        allow(generation_repo).to receive(:find_complete_by_map_id).with(1).and_return(generations)
        allow(generation).to receive(:thumbnail_url).with("https://cdn.example.com").and_return("https://cdn.example.com/alice/map1/gen1/s1zoom_4/tile_0_0.jpg")
        allow(generation).to receive(:metadata_url).with("https://cdn.example.com").and_return("https://cdn.example.com/alice/map1/gen1/mapshot.json")
      end

      it "returns success with map, owner, generations, updated_at, and thumbnail_url" do
        result = operation.call(ulid: "01MAP1")

        expect(result).to be_success
        payload = result.value!
        expect(payload[:map]).to eq(map)
        expect(payload[:owner]).to eq({name: "alice", display_name: "Alice", avatar_url: nil})
        expect(payload[:generations]).to eq([{ulid: "01GEN1", tick: 100, metadata_url: "https://cdn.example.com/alice/map1/gen1/mapshot.json"}])
        expect(payload[:updated_at]).to eq(generation_time)
        expect(payload[:thumbnail_url]).to eq("https://cdn.example.com/alice/map1/gen1/s1zoom_4/tile_0_0.jpg")
      end

      context "when profile has no display name" do
        let(:profile) { double("UserProfile", display_name: nil, avatar_s3_key: nil) }

        it "falls back to user name in owner" do
          result = operation.call(ulid: "01MAP1")

          expect(result.value![:owner]).to include(display_name: "alice")
        end
      end

      context "when profile has an avatar" do
        let(:profile) { double("UserProfile", display_name: "Alice", avatar_s3_key: "avatars/42/abc.jpg") }

        it "resolves avatar_url in owner" do
          result = operation.call(ulid: "01MAP1")

          expect(result.value![:owner]).to include(avatar_url: "https://cdn.example.com/avatars/42/abc.jpg")
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
