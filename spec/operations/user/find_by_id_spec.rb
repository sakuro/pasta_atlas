# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::User::FindById do
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:operation) { PastaAtlas::Operations::User::FindById.new(user_repo:) }

  describe "#call" do
    context "when the user exists" do
      let(:user) { double("User", id: 1, name: "alice") }

      before { allow(user_repo).to receive(:find_by_id).with(1).and_return(user) }

      it "returns success with the user" do
        result = operation.call(user_id: 1)

        expect(result).to be_success
        expect(result.value!).to eq(user)
      end
    end

    context "when the user does not exist" do
      before { allow(user_repo).to receive(:find_by_id).with(999).and_return(nil) }

      it "returns failure with :not_found" do
        result = operation.call(user_id: 999)

        expect(result).to be_failure
        expect(result.failure).to eq(:not_found)
      end
    end
  end
end
