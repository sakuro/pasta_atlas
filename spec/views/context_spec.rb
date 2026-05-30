# frozen_string_literal: true

require "icu4x-data-recommended"

RSpec.describe PastaAtlas::Views::Context do
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:user_preference_repo) { instance_double(PastaAtlas::Repos::UserPreferenceRepo) }
  let(:request) { double("Request", session:) }

  def view_context = PastaAtlas::Views::Context.new(user_repo:, user_profile_repo:, user_preference_repo:, request:)

  context "when not logged in" do
    let(:session) { {} }
    let(:guest_user) { double("User", id: 99) }
    let(:guest_preference) { double("UserPreference", timezone: "UTC", relative_timestamps: false) }

    it "returns nil for current_user_name" do
      expect(view_context.current_user_name).to be_nil
    end

    it "returns nil for current_user_display_name" do
      expect(view_context.current_user_display_name).to be_nil
    end
  end

  context "when logged in" do
    let(:session) { {user_id: 1} }
    let(:user) { double("User", name: "alice") }

    before { allow(user_repo).to receive(:find_by_id).with(1).and_return(user) }

    it "returns the user name" do
      expect(view_context.current_user_name).to eq("alice")
    end

    it "returns nil when the user is not found" do
      allow(user_repo).to receive(:find_by_id).with(1).and_raise(ROM::TupleCountMismatchError)

      expect(view_context.current_user_name).to be_nil
    end

    describe "#current_user_display_name" do
      let(:profile) { double("UserProfile", display_name:) }

      before { allow(user_profile_repo).to receive(:find_by_user_id).with(1).and_return(profile) }

      context "when display_name is set" do
        let(:display_name) { "Alice" }

        it "returns the display name" do
          expect(view_context.current_user_display_name).to eq("Alice")
        end
      end

      context "when display_name is nil" do
        let(:display_name) { nil }

        it "falls back to the user name" do
          expect(view_context.current_user_display_name).to eq("alice")
        end
      end

      context "when the user is not found" do
        let(:display_name) { nil }

        before { allow(user_repo).to receive(:find_by_id).with(1).and_raise(ROM::TupleCountMismatchError) }

        it "returns nil" do
          expect(view_context.current_user_display_name).to be_nil
        end
      end
    end
  end
end
