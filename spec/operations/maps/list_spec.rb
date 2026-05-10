# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Maps::List do
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:generation_repo) { instance_double(PastaAtlas::Repos::GenerationRepo) }
  let(:settings) { double("Settings", cloudfront_base_url: "http://cdn.example.com") }
  let(:operation) { PastaAtlas::Operations::Maps::List.new(map_repo:, user_repo:, generation_repo:, settings:) }

  describe "#call" do
    let(:generation) { double("Generation", metadata_s3_key: "guest/map1/gen1/mapshot.json", tick: 100) }
    let(:map) { double("Map", id: 1, ulid: "01MAP1", user_id: 1) }
    let(:user) { double("User", id: 1) }
    let(:updated_at) { Time.new(2025, 1, 15, 12, 0, 0, "+00:00") }

    before do
      allow(map_repo).to receive(:list_with_complete_generation).with(page: 1, per_page: 20).and_return([map])
      allow(map_repo).to receive(:count_with_complete_generation).and_return(1)
      allow(user_repo).to receive(:find_by_ids).with([1]).and_return([user])
      allow(generation_repo).to receive(:find_latest_complete_by_map_ids).with([1]).and_return({1 => generation})
      allow(generation_repo).to receive(:find_max_created_at_by_map_ids).with([1]).and_return({1 => updated_at})
    end

    it "returns success with maps and their owners" do
      result = operation.call(page: 1)

      expect(result).to be_success
      payload = result.value!
      expect(payload[:maps]).to eq([map])
      expect(payload[:users_by_id]).to eq({1 => user})
      expect(payload[:thumbnail_urls_by_map_ulid]).to eq({"01MAP1" => "http://cdn.example.com/guest/map1/gen1/s1zoom_4/tile_0_0.jpg"})
      expect(payload[:updated_at_by_map_ulid]).to eq({"01MAP1" => updated_at})
      expect(payload[:page]).to eq(1)
      expect(payload[:per_page]).to eq(20)
      expect(payload[:total]).to eq(1)
    end
  end
end
