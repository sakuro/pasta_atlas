# frozen_string_literal: true

RSpec.describe PastaAtlas::Repos::AvatarUploadRepo, :db do
  let(:repo) { Hanami.app["repos.avatar_upload_repo"] }
  let(:user) { Factory[:user] }
  let(:now) { Time.utc(2026, 11, 22, 12, 0, 0) }

  def issue(**attributes) = Factory[:avatar_upload, user:, expires_at: now + 3600, **attributes]

  describe "#create" do
    it "records the issued key" do
      upload = repo.create(user_id: user.id, s3_key: "u/avatar/a.png", content_type: "image/png", expires_at: now + 3600)

      expect(upload).to have_attributes(user_id: user.id, s3_key: "u/avatar/a.png", content_type: "image/png", consumed_at: nil)
    end
  end

  describe "#find_pending" do
    it "finds an upload issued to the user that is unexpired and not applied" do
      upload = issue

      expect(repo.find_pending(user_id: user.id, s3_key: upload.s3_key, now:)).to have_attributes(id: upload.id)
    end

    it "does not find the key for another user" do
      upload = issue

      expect(repo.find_pending(user_id: Factory[:user].id, s3_key: upload.s3_key, now:)).to be_nil
    end

    it "does not find an expired upload" do
      upload = issue(expires_at: now - 1)

      expect(repo.find_pending(user_id: user.id, s3_key: upload.s3_key, now:)).to be_nil
    end

    it "does not find an upload that was applied" do
      upload = issue(consumed_at: now - 60)

      expect(repo.find_pending(user_id: user.id, s3_key: upload.s3_key, now:)).to be_nil
    end
  end

  describe "#count_pending" do
    it "counts only the unexpired, unapplied uploads of the user" do
      2.times { issue }
      issue(expires_at: now - 1)
      issue(consumed_at: now - 60)
      Factory[:avatar_upload, user: Factory[:user], expires_at: now + 3600]

      expect(repo.count_pending(user_id: user.id, now:)).to eq(2)
    end
  end

  describe "#consume" do
    it "marks the upload applied once" do
      upload = issue

      expect(repo.consume(id: upload.id, now:)).to eq(1)
      expect(repo.consume(id: upload.id, now:)).to eq(0)
    end
  end

  describe "#delete_expired_before" do
    it "deletes the uploads that expired before the time and returns how many" do
      issue(expires_at: now - 7200)
      issue(expires_at: now - 60)
      kept = issue

      expect(repo.delete_expired_before(now - 3600)).to eq(1)
      expect(repo.find_pending(user_id: user.id, s3_key: kept.s3_key, now:)).not_to be_nil
    end
  end
end
