# frozen_string_literal: true

RSpec.describe PastaAtlas::Repos::UploadVerificationKeyRepo, :db do
  let(:repo) { Hanami.app["repos.upload_verification_key_repo"] }
  let(:upload) { Factory[:upload] }
  let(:keys) { %w[a/tile_0_0.jpg a/tile_1_0.jpg] }

  describe "#create_many" do
    it "ignores keys that already exist" do
      repo.create_many(upload_id: upload.id, s3_keys: keys)

      expect { repo.create_many(upload_id: upload.id, s3_keys: keys) }.not_to raise_error
    end
  end

  describe "#count and #count_among" do
    before { repo.create_many(upload_id: upload.id, s3_keys: keys) }

    it "counts the keys of the upload" do
      expect(repo.count(upload_id: upload.id)).to eq(2)
      expect(repo.count(upload_id: Factory[:upload].id)).to eq(0)
    end

    it "counts how many of the given keys the upload already has" do
      expect(repo.count_among(upload_id: upload.id, s3_keys: [keys.first, "a/tile_9_9.jpg"])).to eq(1)
    end
  end

  describe "#mark_verified_batch" do
    before { repo.create_many(upload_id: upload.id, s3_keys: keys) }

    it "marks the given keys" do
      repo.mark_verified_batch(upload_id: upload.id, results: [{s3_key: keys.first, size_bytes: 10}])

      expect(repo.count_verified(upload_id: upload.id)).to eq(1)
    end
  end

  describe "#sum_verified_size_bytes" do
    before { repo.create_many(upload_id: upload.id, s3_keys: keys) }

    it "sums the sizes of the verified keys of the upload" do
      repo.mark_verified_batch(upload_id: upload.id, results: [{s3_key: keys.first, size_bytes: 10}])
      repo.mark_verified_batch(upload_id: upload.id, results: [{s3_key: "a/unissued.jpg", size_bytes: 20}])
      Factory[:upload_verification_key, size_bytes: 40]

      expect(repo.sum_verified_size_bytes(upload_id: upload.id)).to be(10)
    end

    it "returns 0 when no key is verified" do
      expect(repo.sum_verified_size_bytes(upload_id: upload.id)).to be(0)
    end
  end
end
