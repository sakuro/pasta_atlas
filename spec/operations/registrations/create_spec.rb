# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::Registrations::Create do
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:user_preference_repo) { instance_double(PastaAtlas::Repos::UserPreferenceRepo) }
  let(:credential_repo) { instance_double(PastaAtlas::Repos::CredentialRepo) }
  let(:import_avatar) { instance_double(PastaAtlas::Operations::Registrations::ImportAvatar) }
  let(:operation) do
    PastaAtlas::Operations::Registrations::Create.new(
      user_repo:, user_profile_repo:, user_preference_repo:, credential_repo:, import_avatar:
    )
  end

  let(:user) { double("User", id: 1, name: "alice") }

  describe "#call" do
    context "when the name is empty" do
      it "returns failure with :invalid and error key" do
        result = operation.call(name: "", timezone: "UTC", provider: "github", uid: "123", avatar_url: "")

        expect(result).to be_failure
        expect(result.failure).to eq([:invalid, "error-username-empty"])
      end
    end

    context "when the name is too long" do
      it "returns failure with :invalid and error key" do
        result = operation.call(name: "a" * 40, timezone: "UTC", provider: "github", uid: "123", avatar_url: "")

        expect(result).to be_failure
        expect(result.failure).to eq([:invalid, "error-username-too-long"])
      end
    end

    context "when the name contains invalid characters" do
      it "returns failure with :invalid and error key" do
        result = operation.call(name: "alice!", timezone: "UTC", provider: "github", uid: "123", avatar_url: "")

        expect(result).to be_failure
        expect(result.failure).to eq([:invalid, "error-username-invalid-chars"])
      end
    end

    context "when the name is reserved" do
      it "returns failure with :invalid and error key" do
        result = operation.call(name: "admin", timezone: "UTC", provider: "github", uid: "123", avatar_url: "")

        expect(result).to be_failure
        expect(result.failure).to eq([:invalid, "error-username-reserved"])
      end
    end

    context "when the name is already taken" do
      before { allow(user_repo).to receive(:find_by_name).with("alice").and_return(user) }

      it "returns failure with :invalid and error key" do
        result = operation.call(name: "alice", timezone: "UTC", provider: "github", uid: "123", avatar_url: "")

        expect(result).to be_failure
        expect(result.failure).to eq([:invalid, "error-username-taken"])
      end
    end

    context "when registration succeeds" do
      before do
        allow(user_repo).to receive(:find_by_name).with("alice").and_return(nil)
        allow(user_repo).to receive(:transaction).and_yield
        allow(user_repo).to receive(:create).with(name: "alice").and_return(user)
        allow(user_profile_repo).to receive(:create).with(user_id: 1)
        allow(user_preference_repo).to receive(:create).with(user_id: 1, timezone: "Asia/Tokyo")
        allow(credential_repo).to receive(:create).with(user_id: 1, provider: "github", uid: "123")
        allow(import_avatar).to receive(:call).with(user:, avatar_url: "http://example.com/avatar.jpg").and_return(Failure(:error))
      end

      it "returns success with the created user" do
        result = operation.call(name: "alice", timezone: "Asia/Tokyo", provider: "github", uid: "123", avatar_url: "http://example.com/avatar.jpg")

        expect(result).to be_success
        expect(result.value!).to eq(user)
      end
    end
  end
end
