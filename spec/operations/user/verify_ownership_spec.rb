# frozen_string_literal: true

RSpec.describe PastaAtlas::Operations::User::VerifyOwnership do
  let(:operation) { PastaAtlas::Operations::User::VerifyOwnership.new }

  let(:user) { double("User", id: 1, name: "sakuro") }
  let(:guest) { double("User", id: 0, name: "guest") }

  describe "#call" do
    context "when current_user owns the resource" do
      it "returns Success with the user" do
        result = operation.call(current_user: user, user_name: "sakuro")

        expect(result).to be_success
        expect(result.value!).to eq(user)
      end
    end

    context "when current_user does not own the resource" do
      it "returns Failure(:forbidden)" do
        result = operation.call(current_user: guest, user_name: "sakuro")

        expect(result).to be_failure
        expect(result.failure).to eq(:forbidden)
      end
    end
  end
end
