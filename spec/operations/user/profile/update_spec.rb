# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::User::Profile::Update do
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:operation) { PastaAtlas::Operations::User::Profile::Update.new(user_profile_repo:) }

  let(:user) { double("User", id: 1, name: "sakuro") }

  describe "#call" do
    context "when display_name is valid" do
      before { allow(user_profile_repo).to receive(:update_profile) }

      it "updates profile and returns the user" do
        result = operation.call(user:, display_name: "Sakuro", avatar_s3_key: "")

        expect(result).to be_success
        expect(result.value!).to eq(user)
        expect(user_profile_repo).to have_received(:update_profile).with(1, display_name: "Sakuro")
      end
    end

    context "when display_name is blank" do
      before { allow(user_profile_repo).to receive(:update_profile) }

      it "clears display_name" do
        operation.call(user:, display_name: "", avatar_s3_key: "")

        expect(user_profile_repo).to have_received(:update_profile).with(1, display_name: nil)
      end
    end

    context "when display_name exceeds 30 grapheme clusters" do
      it "returns Failure([:invalid, message])" do
        result = operation.call(user:, display_name: "あ" * 31, avatar_s3_key: "")

        expect(result).to be_failure
        code, message = result.failure
        expect(code).to eq(:invalid)
        expect(message).to eq("error-profile-display-name-too-long")
      end
    end

    context "when display_name contains disallowed characters" do
      it "returns Failure([:invalid, message])" do
        result = operation.call(user:, display_name: "bad\tname", avatar_s3_key: "")

        expect(result).to be_failure
        code, _message = result.failure
        expect(code).to eq(:invalid)
      end
    end

    context "when a valid avatar_s3_key is provided" do
      before do
        allow(user_profile_repo).to receive(:update_profile)
        allow(user_profile_repo).to receive(:update_avatar)
      end

      it "updates the avatar" do
        operation.call(user:, display_name: "Sakuro", avatar_s3_key: "sakuro/avatar/abc.jpg")

        expect(user_profile_repo).to have_received(:update_avatar).with(1, avatar_s3_key: "sakuro/avatar/abc.jpg")
      end
    end
  end
end
