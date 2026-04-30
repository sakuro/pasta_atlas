# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Maps::List do
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:operation) { PastaAtlas::Operations::Maps::List.new(map_repo:, user_repo:) }

  describe "#call" do
    let(:map) { double("Map", user_id: 1) }
    let(:user) { double("User", id: 1) }

    before do
      allow(map_repo).to receive(:list_with_complete_generation).with(page: 1, per_page: 20).and_return([map])
      allow(map_repo).to receive(:count_with_complete_generation).and_return(1)
      allow(user_repo).to receive(:find_by_ids).with([1]).and_return([user])
    end

    it "returns success with maps and their owners" do
      result = operation.call(page: 1)

      expect(result).to be_success
      payload = result.value!
      expect(payload[:maps]).to eq([map])
      expect(payload[:users_by_id]).to eq({1 => user})
      expect(payload[:page]).to eq(1)
      expect(payload[:per_page]).to eq(20)
      expect(payload[:total]).to eq(1)
    end
  end
end
