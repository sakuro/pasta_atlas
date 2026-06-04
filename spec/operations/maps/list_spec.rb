# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Maps::List do
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:generation_repo) { instance_double(PastaAtlas::Repos::GenerationRepo) }
  let(:settings) { double("Settings", cloudfront_base_url: "http://cdn.example.com") }
  let(:operation) { PastaAtlas::Operations::Maps::List.new(map_repo:, user_repo:, user_profile_repo:, generation_repo:, settings:) }

  describe "#call" do
    let(:generation) { double("Generation", tick: 100) }
    let(:map) { double("Map", id: 1, ulid: "01MAP1", user_id: 1, display_name: "Map 1") }
    let(:user) { double("User", id: 1, name: "alice") }
    let(:profile) { double("UserProfile", user_id: 1, display_name: "Alice", avatar_s3_key: nil) }
    let(:updated_at) { Time.new(2025, 1, 15, 12, 0, 0, "+00:00") }

    before do
      allow(map_repo).to receive(:list_with_complete_generation).with(page: 1, per_page: 20).and_return([map])
      allow(map_repo).to receive(:count_with_complete_generation).and_return(1)
      allow(user_repo).to receive(:find_by_ids).with([1]).and_return([user])
      allow(user_profile_repo).to receive(:find_by_user_ids).with([1]).and_return([profile])
      allow(generation_repo).to receive(:find_latest_complete_by_map_ids).with([1]).and_return({1 => generation})
      allow(generation_repo).to receive(:find_max_created_at_by_map_ids).with([1]).and_return({1 => updated_at})
      allow(generation).to receive(:thumbnail_url).with("http://cdn.example.com").and_return("http://cdn.example.com/guest/map1/gen1/s1zoom_4/tile_0_0.jpg")
      allow(generation).to receive(:metadata_url).with("http://cdn.example.com").and_return("http://cdn.example.com/guest/map1/gen1/mapshot.json")
    end

    it "returns success with maps and their owners" do
      result = operation.call(page: 1)

      expect(result).to be_success
      payload = result.value!

      expect(payload[:map_infos].size).to eq(1)
      map_info = payload[:map_infos].first
      expect(map_info.ulid).to eq("01MAP1")
      expect(map_info.display_name).to eq("Map 1")
      expect(map_info.user_info.name).to eq("alice")
      expect(map_info.user_info.display_name).to eq("Alice")
      expect(map_info.user_info.avatar_url).to be_nil
      expect(map_info.thumbnail_url).to eq("http://cdn.example.com/guest/map1/gen1/s1zoom_4/tile_0_0.jpg")
      expect(map_info.metadata_url).to eq("http://cdn.example.com/guest/map1/gen1/mapshot.json")
      expect(map_info.updated_at).to eq(updated_at)

      expect(payload[:page]).to eq(1)
      expect(payload[:per_page]).to eq(20)
      expect(payload[:total]).to eq(1)
    end
  end
end
