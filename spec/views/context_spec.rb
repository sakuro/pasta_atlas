# frozen_string_literal: true

RSpec.describe PastaAtlas::Views::Context do
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:request) { double("Request", session:) }

  def view_context = PastaAtlas::Views::Context.new(user_repo:, request:)

  context "when not logged in" do
    let(:session) { {} }

    it "returns nil" do
      expect(view_context.current_user_profile_name).to be_nil
    end
  end

  context "when logged in" do
    let(:session) { {user_id: 1} }

    it "returns the user name" do
      allow(user_repo).to receive(:find_by_id).with(1).and_return(double("User", name: "alice"))

      expect(view_context.current_user_profile_name).to eq("alice")
    end

    it "returns nil when the user is not found" do
      allow(user_repo).to receive(:find_by_id).with(1).and_raise(ROM::TupleCountMismatchError)

      expect(view_context.current_user_profile_name).to be_nil
    end
  end
end
