# frozen_string_literal: true

RSpec.describe PastaAtlas::Repos::UploadRepo, :db do
  let(:repo) { Hanami.app["repos.upload_repo"] }
  let(:now) { Time.now }

  def upload_created(days_ago:)
    Factory[:upload, created_at: now - (days_ago * 24 * 60 * 60)]
  end

  def stale_generation_ids
    repo.find_stale_incomplete(before: now - (7 * 24 * 60 * 60)).map(&:generation_id)
  end

  describe "#create" do
    it "stores the upload as pending and returns it" do
      generation = Factory[:generation]
      ulid = ULID.generate

      created = repo.create(ulid:, generation_id: generation.id, total_image_count: 7, metadata_bytes: 123)

      expect(repo.find_by_ulid(ulid)).to have_attributes(
        id: created.id, generation_id: generation.id, total_image_count: 7, metadata_bytes: 123, verification_status: "pending"
      )
    end
  end

  describe "#find_stale_incomplete" do
    it "returns an old upload that has no status yet" do
      upload = upload_created(days_ago: 8)

      expect(stale_generation_ids).to eq([upload.generation_id])
    end

    it "returns an old upload whose status is pending or failed" do
      pending_upload = upload_created(days_ago: 8)
      failed_upload = upload_created(days_ago: 9)
      Factory[:upload_event, upload: pending_upload, event_type: "pending"]
      Factory[:upload_event, upload: failed_upload, event_type: "failed"]

      expect(stale_generation_ids).to contain_exactly(pending_upload.generation_id, failed_upload.generation_id)
    end

    it "returns the data needed to build the S3 prefix" do
      upload = upload_created(days_ago: 8)
      generation = Hanami.app["repos.generation_repo"].find_by_id!(upload.generation_id)
      map = Hanami.app["repos.map_repo"].find_by_id!(generation.map_id)
      user = Hanami.app["repos.user_repo"].find_by_id!(map.user_id)

      row = repo.find_stale_incomplete(before: now - (7 * 24 * 60 * 60)).first

      expect(row).to eq(PastaAtlas::Values::StaleUpload[generation_id: generation.id, user_name: user.name, mapshot_map_id: map.mapshot_map_id, mapshot_unique_id: generation.mapshot_unique_id])
    end

    it "skips a recent upload" do
      upload_created(days_ago: 1)

      expect(stale_generation_ids).to be_empty
    end

    it "skips a complete upload however old it is" do
      upload = upload_created(days_ago: 30)
      Factory[:upload_event, upload:, event_type: "pending", occurred_at: now - (30 * 24 * 60 * 60)]
      Factory[:upload_event, upload:, event_type: "complete", occurred_at: now - (29 * 24 * 60 * 60)]

      expect(stale_generation_ids).to be_empty
    end

    it "skips an old upload that verified a key recently" do
      upload = upload_created(days_ago: 30)
      Factory[:upload_verification_key, upload:, verified_at: now - (60 * 60)]

      expect(stale_generation_ids).to be_empty
    end

    it "returns an old upload whose last verified key is old too" do
      upload = upload_created(days_ago: 30)
      Factory[:upload_verification_key, upload:, verified_at: now - (10 * 24 * 60 * 60)]

      expect(stale_generation_ids).to eq([upload.generation_id])
    end
  end

  describe "#update_verification" do
    it "stores the status and the time" do
      upload = Factory[:upload]
      verified_at = Time.at(Time.now.to_i)

      repo.update_verification(id: upload.id, verification_status: "passed", verified_at:)

      expect(repo.find_by_ulid(upload.ulid)).to have_attributes(verification_status: "passed", verified_at:)
    end
  end
end
