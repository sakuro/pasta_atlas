# frozen_string_literal: true

RSpec.describe PastaAtlas::Views::Context do
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:user_profile_repo) { instance_double(PastaAtlas::Repos::UserProfileRepo) }
  let(:user_preference_repo) { instance_double(PastaAtlas::Repos::UserPreferenceRepo) }
  let(:request) { double("Request", session:) }

  def view_context = PastaAtlas::Views::Context.new(user_repo:, user_profile_repo:, user_preference_repo:, request:)

  context "when not logged in" do
    let(:session) { {} }
    let(:guest_user) { double("User", id: 99) }
    let(:guest_preference) { double("UserPreference", timezone: "UTC") }

    it "returns nil for current_user_name" do
      expect(view_context.current_user_name).to be_nil
    end

    it "returns nil for current_user_display_name" do
      expect(view_context.current_user_display_name).to be_nil
    end

    describe "#localize_date" do
      before do
        allow(user_repo).to receive(:find_by_name).with("guest").and_return(guest_user)
        allow(user_preference_repo).to receive(:find_by_user_id).with(99).and_return(guest_preference)
      end

      it "returns a Foxtail::Function::DateTime with the guest timezone" do
        time = Time.utc(2025, 1, 16, 5, 0, 0)
        result = view_context.localize_date(time)
        expect(result).to be_a(Foxtail::Function::DateTime)
        expect(result.options).to eq({timeZone: "UTC"})
      end
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

    describe "#localize_date" do
      let(:preference) { double("UserPreference", timezone: "Asia/Tokyo") }

      before { allow(user_preference_repo).to receive(:find_by_user_id).with(1).and_return(preference) }

      it "returns a Foxtail::Function::DateTime with the user's timezone" do
        time = Time.utc(2025, 1, 15, 23, 0, 0)
        result = view_context.localize_date(time)
        expect(result).to be_a(Foxtail::Function::DateTime)
        expect(result.options).to eq({timeZone: "Asia/Tokyo"})
      end

      it "preserves the UTC time as the value" do
        time = Time.utc(2025, 1, 15, 23, 0, 0)
        result = view_context.localize_date(time)
        expect(result.value).to eq(time)
      end
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
