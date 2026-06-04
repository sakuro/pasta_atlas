# frozen_string_literal: true

RSpec.describe PastaAtlas::Resolvers::UserResolver do
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:guest) { double("User", id: 0, name: "guest") }
  let(:resolver) { PastaAtlas::Resolvers::UserResolver.new(user_repo:, guest:) }

  describe "#call" do
    context "when user_id is nil" do
      it "returns the guest user" do
        expect(resolver.call(nil)).to eq(guest)
      end
    end

    context "when user_id is valid" do
      let(:user) { double("User", id: 1, name: "alice") }

      before { allow(user_repo).to receive(:find_by_id).with(1).and_return(user) }

      it "returns the authenticated user" do
        expect(resolver.call(1)).to eq(user)
      end
    end

    context "when user_id is stale" do
      before { allow(user_repo).to receive(:find_by_id).with(999).and_raise(ROM::TupleCountMismatchError) }

      it "returns the guest user" do
        expect(resolver.call(999)).to eq(guest)
      end
    end
  end
end
