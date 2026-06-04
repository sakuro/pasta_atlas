# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Maps::ListRecentByUser do
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:generation_repo) { instance_double(PastaAtlas::Repos::GenerationRepo) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:settings) { double("Settings", cloudfront_base_url: "http://cdn.example.com") }
  let(:operation) { PastaAtlas::Operations::Maps::ListRecentByUser.new(map_repo:, generation_repo:, user_repo:, user_profile_repo:, settings:) }

  let(:user) { double("User", name: "alice") }
  let(:profile) { double("UserProfile", display_name: "Alice", avatar_s3_key: nil) }

  before do
    allow(user_repo).to receive(:find_by_id).with(1).and_return(user)
    allow(user_profile_repo).to receive(:find_by_user_id).with(1).and_return(profile)
  end

  describe "#call" do
    context "when the user has maps" do
      let(:map) { double("Map", id: 1, ulid: "01MAP1", display_name: "Map 1") }
      let(:generation) { double("Generation") }
      let(:updated_at) { Time.new(2025, 1, 15, 12, 0, 0, "+00:00") }

      before do
        allow(map_repo).to receive(:list_with_complete_generation_by_user).with(user_id: 1, limit: 3).and_return([map])
        allow(generation_repo).to receive(:find_latest_complete_by_map_ids).with([1]).and_return({1 => generation})
        allow(generation_repo).to receive(:find_max_created_at_by_map_ids).with([1]).and_return({1 => updated_at})
        allow(generation).to receive(:thumbnail_url).with("http://cdn.example.com").and_return("http://cdn.example.com/user/1/map1/gen1/s1zoom_4/tile_0_0.jpg")
        allow(generation).to receive(:metadata_url).with("http://cdn.example.com").and_return("http://cdn.example.com/user/1/map1/gen1/mapshot.json")
      end

      it "returns success with map infos" do
        result = operation.call(user_id: 1)

        expect(result).to be_success
        map_infos = result.value!
        expect(map_infos.size).to eq(1)

        map_info = map_infos.first
        expect(map_info.ulid).to eq("01MAP1")
        expect(map_info.display_name).to eq("Map 1")
        expect(map_info.user_info).to eq(PastaAtlas::Values::UserInfo[name: "alice", display_name: "Alice", avatar_url: nil])
        expect(map_info.thumbnail_url).to eq("http://cdn.example.com/user/1/map1/gen1/s1zoom_4/tile_0_0.jpg")
        expect(map_info.metadata_url).to eq("http://cdn.example.com/user/1/map1/gen1/mapshot.json")
        expect(map_info.updated_at).to eq(updated_at)
      end
    end

    context "when the user has no maps" do
      before do
        allow(map_repo).to receive(:list_with_complete_generation_by_user).with(user_id: 1, limit: 3).and_return([])
        allow(generation_repo).to receive(:find_latest_complete_by_map_ids).with([]).and_return({})
        allow(generation_repo).to receive(:find_max_created_at_by_map_ids).with([]).and_return({})
      end

      it "returns success with an empty list" do
        result = operation.call(user_id: 1)

        expect(result).to be_success
        expect(result.value!).to be_empty
      end
    end
  end
end
