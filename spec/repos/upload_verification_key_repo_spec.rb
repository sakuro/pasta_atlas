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

  describe "#mark_verified_batch" do
    before { repo.create_many(upload_id: upload.id, s3_keys: keys) }

    it "marks the given keys" do
      repo.mark_verified_batch(upload_id: upload.id, results: [{s3_key: keys.first, size_bytes: 10}])

      expect(repo.count_verified(upload_id: upload.id)).to eq(1)
    end
  end
end
