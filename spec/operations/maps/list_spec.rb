# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Maps::List do
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:operation) { PastaAtlas::Operations::Maps::List.new(map_repo:, user_profile_repo:) }

  describe "#call" do
    let(:map) { double("Map", user_id: 1) }
    let(:user_profile) { double("UserProfile", user_id: 1) }

    before do
      allow(map_repo).to receive(:list_with_complete_generation).with(page: 1, per_page: 20).and_return([map])
      allow(map_repo).to receive(:count_with_complete_generation).and_return(1)
      allow(user_profile_repo).to receive(:find_by_user_ids).with([1]).and_return([user_profile])
    end

    it "returns success with maps and their owners" do
      result = operation.call(page: 1)

      expect(result).to be_success
      payload = result.value!
      expect(payload[:maps]).to eq([map])
      expect(payload[:user_profiles_by_id]).to eq({1 => user_profile})
      expect(payload[:page]).to eq(1)
      expect(payload[:per_page]).to eq(20)
      expect(payload[:total]).to eq(1)
    end
  end
end
