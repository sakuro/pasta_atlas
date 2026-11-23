# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Uploads::VerifyBatches::Create, :db do
  let(:verify_batch) { instance_double(PastaAtlas::Operations::Uploads::VerifyBatch) }
  let(:action) { PastaAtlas::Actions::API::Uploads::VerifyBatches::Create.new(verify_batch:) }

  let(:upload) { Factory[:upload] }
  let(:user_id) do
    generation = Hanami.app["repos.generation_repo"].find_by_id!(upload.generation_id)
    Hanami.app["repos.map_repo"].find_by_id!(generation.map_id).user_id
  end
  let(:session) { {"rack.session" => {"user_id" => user_id}} }
  let(:request_env) { session.merge(ulid: upload.ulid, filenames: ["s0zoom_4/tile_0_0.jpg"]) }

  context "when the batch is verified" do
    before { allow(verify_batch).to receive(:call).and_return(Success({verified_bytes: 1024})) }

    it "returns 200 with the bytes of the batch" do
      response = action.call(request_env)

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body.join)).to eq({"verified_bytes" => 1024})
    end
  end

  context "when the upload is not pending" do
    before { allow(verify_batch).to receive(:call).and_return(Failure(:unprocessable_entity)) }

    it "returns 422" do
      response = action.call(request_env)

      expect(response.status).to eq(422)
    end
  end
end
