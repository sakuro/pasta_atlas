# frozen_string_literal: true

require "base64"
require "json"

RSpec.describe PastaAtlas::Operations::User::AvatarPresignedPost::Create, :db do
  let(:operation) { Hanami.app["operations.user.avatar_presigned_post.create"] }
  let(:user) { Factory[:user, name: "testuser"] }

  def policy_conditions(presigned_post)
    JSON.parse(Base64.decode64(presigned_post[:fields]["policy"]))["conditions"]
  end

  describe "#call" do
    it "returns a presigned POST and the key under the user's avatar prefix" do
      result = operation.call(user_id: user.id, content_type: "image/png")

      expect(result).to be_success
      value = result.value!
      expect(value[:s3_key]).to match(%r{\Atestuser/avatar/[0-9A-Z]{26}\.png\z})
      expect(value[:presigned_post]).to match(url: be_a(String), fields: be_a(Hash))
      expect(value[:presigned_post][:fields]).to include("key" => value[:s3_key])
    end

    it "constrains the content type and the object size in the policy" do
      value = operation.call(user_id: user.id, content_type: "image/webp").value!

      conditions = policy_conditions(value[:presigned_post])
      expect(conditions).to include(["content-length-range", 1, 5 * 1024 * 1024])
      expect(conditions).to include({"Content-Type" => "image/webp"})
    end

    it "records the issued key so that it can be applied later" do
      value = operation.call(user_id: user.id, content_type: "image/png").value!

      upload = Hanami.app["repos.avatar_upload_repo"].find_pending(user_id: user.id, s3_key: value[:s3_key], now: Time.now)
      expect(upload).to have_attributes(content_type: "image/png")
    end

    context "when the user already has 10 issued keys that were not applied" do
      before { 10.times { Factory[:avatar_upload, user:] } }

      it "returns Failure(:too_many_requests) and issues nothing" do
        result = operation.call(user_id: user.id, content_type: "image/png")

        expect(result).to be_failure
        expect(result.failure).to eq(:too_many_requests)
        expect(Hanami.app["repos.avatar_upload_repo"].count_pending(user_id: user.id, now: Time.now)).to eq(10)
      end

      it "issues a key again once the others expired or were applied" do
        Hanami.app["repos.avatar_upload_repo"].delete_expired_before(Time.now + 7200)

        expect(operation.call(user_id: user.id, content_type: "image/png")).to be_success
      end
    end

    it "returns a forbidden failure when the user is not authenticated" do
      result = operation.call(user_id: nil, content_type: "image/png")

      expect(result).to be_failure
      expect(result.failure).to eq(:forbidden)
    end
  end
end
