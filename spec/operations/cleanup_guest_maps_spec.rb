# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::CleanupGuestMaps, :db do
  let(:operation) { Hanami.app["operations.cleanup_guest_maps"] }
  let(:guest_user) { Factory[:user, name: "guest"] }
  let(:regular_user) { Factory[:user] }

  def generation_count = Hanami.app["relations.generations"].dataset.count
  def map_count = Hanami.app["relations.maps"].dataset.count

  describe "#call" do
    context "when there are no expired generations" do
      it "returns zeros" do
        result = operation.call

        expect(result).to be_success
        expect(result.value!).to eq({deleted_generations: 0, deleted_maps: 0})
      end
    end

    context "with an expired generation whose map has no other generations" do
      let(:guest_map) { Factory[:map, user: guest_user] }
      let!(:expired_generation) { Factory[:generation, :expired, map: guest_map] }

      it "deletes the expired generation" do
        expect { operation.call }.to change { generation_count }.by(-1)
      end

      it "deletes the orphaned map" do
        expect { operation.call }.to change { map_count }.by(-1)
      end

      it "returns the correct counts" do
        result = operation.call

        expect(result).to be_success
        expect(result.value!).to eq({deleted_generations: 1, deleted_maps: 1})
      end
    end

    context "with expired and active generations on the same map" do
      let(:guest_map) { Factory[:map, user: guest_user] }
      let!(:expired_generation) { Factory[:generation, :expired, map: guest_map] }
      let!(:active_generation) do
        Factory[:generation, map: guest_map, expires_at: Time.now + (8 * 86400)]
      end

      it "deletes only the expired generation" do
        expect { operation.call }.to change { generation_count }.by(-1)
      end

      it "keeps the map" do
        expect { operation.call }.not_to change { map_count }
      end
    end

    context "with a non-expired guest generation" do
      let(:guest_map) { Factory[:map, user: guest_user] }
      let!(:active_generation) do
        Factory[:generation, map: guest_map, expires_at: Time.now + (8 * 86400)]
      end

      it "does not delete the generation" do
        expect { operation.call }.not_to change { generation_count }
      end
    end

    context "with a regular user's generation" do
      let(:regular_map) { Factory[:map, user: regular_user] }
      let!(:generation) { Factory[:generation, map: regular_map] }

      it "does not delete regular user generations" do
        expect { operation.call }.not_to change { generation_count }
      end

      it "does not delete regular user maps" do
        expect { operation.call }.not_to change { map_count }
      end
    end
  end
end
