# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::User::FindByName do
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:operation) { PastaAtlas::Operations::User::FindByName.new(user_repo:) }

  describe "#call" do
    context "when the user exists" do
      let(:user) { double("User", id: 1, name: "alice") }

      before { allow(user_repo).to receive(:find_by_name).with("alice").and_return(user) }

      it "returns success with the user" do
        result = operation.call(user_name: "alice")

        expect(result).to be_success
        expect(result.value!).to eq(user)
      end
    end

    context "when the user does not exist" do
      before { allow(user_repo).to receive(:find_by_name).with("nobody").and_return(nil) }

      it "returns failure with :not_found" do
        result = operation.call(user_name: "nobody")

        expect(result).to be_failure
        expect(result.failure).to eq(:not_found)
      end
    end
  end
end
