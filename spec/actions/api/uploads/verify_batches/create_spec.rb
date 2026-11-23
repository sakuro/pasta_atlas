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
  let(:filenames) { ["s0zoom_4/tile_0_0.jpg"] }
  let(:request_env) { session.merge(ulid: upload.ulid, filenames:) }

  before { allow(verify_batch).to receive(:call) }

  context "when the batch is verified" do
    before { allow(verify_batch).to receive(:call).and_return(Success({verified_bytes: 1024})) }

    it "returns 200 with the bytes of the batch" do
      response = action.call(request_env)

      expect(response.status).to eq(200)
      expect(response).to conform_to_openapi("POST /api/v1/uploads/{ulid}/verify_batch")
      expect(JSON.parse(response.body.join)).to eq({"verified_bytes" => 1024})
    end
  end

  context "when no session" do
    it "returns 403 without calling the operation" do
      response = action.call(request_env.merge("rack.session" => {}))

      expect(response.status).to eq(403)
      expect(response).to conform_to_openapi("POST /api/v1/uploads/{ulid}/verify_batch")
      expect(verify_batch).not_to have_received(:call)
    end
  end

  context "when the upload belongs to another user" do
    let(:other_user) { Factory[:user] }

    it "returns 403 without calling the operation" do
      response = action.call(request_env.merge("rack.session" => {"user_id" => other_user.id}))

      expect(response.status).to eq(403)
      expect(response).to conform_to_openapi("POST /api/v1/uploads/{ulid}/verify_batch")
      expect(verify_batch).not_to have_received(:call)
    end
  end

  context "when the upload does not exist" do
    it "returns 404 without calling the operation" do
      response = action.call(request_env.merge(ulid: "01UNKNOWNUPLOAD"))

      expect(response.status).to eq(404)
      expect(response).to conform_to_openapi("POST /api/v1/uploads/{ulid}/verify_batch")
      expect(verify_batch).not_to have_received(:call)
    end
  end

  context "when filenames is empty" do
    let(:filenames) { [] }

    it "returns 400 without calling the operation" do
      response = action.call(request_env)

      expect(response.status).to eq(400)
      expect(response).to conform_to_openapi("POST /api/v1/uploads/{ulid}/verify_batch")
      expect(verify_batch).not_to have_received(:call)
    end
  end

  context "when there are more than 200 filenames" do
    let(:filenames) { Array.new(201) {|i| "s0zoom_4/tile_#{i}_0.jpg" } }

    it "returns 400 without calling the operation" do
      response = action.call(request_env)

      expect(response.status).to eq(400)
      expect(response).to conform_to_openapi("POST /api/v1/uploads/{ulid}/verify_batch")
      expect(verify_batch).not_to have_received(:call)
    end
  end

  context "when an object is missing" do
    before { allow(verify_batch).to receive(:call).and_return(Failure(:verification_failed)) }

    it "returns 422 with verification_failed" do
      response = action.call(request_env)

      expect(response.status).to eq(422)
      expect(response).to conform_to_openapi("POST /api/v1/uploads/{ulid}/verify_batch")
      expect(JSON.parse(response.body.join)).to eq({"error" => "verification_failed"})
    end
  end

  context "when the upload is not pending" do
    before { allow(verify_batch).to receive(:call).and_return(Failure(:unprocessable_entity)) }

    it "returns 422 with not_pending" do
      response = action.call(request_env)

      expect(response.status).to eq(422)
      expect(response).to conform_to_openapi("POST /api/v1/uploads/{ulid}/verify_batch")
      expect(JSON.parse(response.body.join)).to eq({"error" => "not_pending"})
    end
  end

  context "when the cleanup message cannot be queued" do
    before { allow(verify_batch).to receive(:call).and_return(Failure(:sqs_error)) }

    it "returns 500" do
      response = action.call(request_env)

      expect(response.status).to eq(500)
      expect(response).to conform_to_openapi("POST /api/v1/uploads/{ulid}/verify_batch")
    end
  end
end
