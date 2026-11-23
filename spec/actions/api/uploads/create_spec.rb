# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Uploads::Create, :db do
  let(:create_upload) { instance_double(PastaAtlas::Operations::Uploads::Create) }
  let(:guest) { double("User", id: 99) }
  let(:action) do
    PastaAtlas::Actions::API::Uploads::Create.new(create_upload:, guest:)
  end

  let(:session) { {"rack.session" => {"user_id" => 1}} }
  let(:action_params) do
    {metadata: {"map_id" => "ae8ec3ab", "unique_id" => "550f41a9", "tick" => 1000}, total_image_count: 5, name: "My Map"}
  end

  let(:upload) { double("Upload", ulid: "01UPLOAD") }
  let(:generation) { double("Generation", ulid: "01GEN") }
  let(:map) { double("Map", ulid: "01MAP") }

  context "when no session" do
    it "returns 403" do
      response = action.call({"rack.session" => {}}.merge(action_params))

      expect(response.status).to eq(403)
      expect(response).to conform_to_openapi("POST /api/v1/uploads")
    end
  end

  context "when authenticated" do
    context "when the operation succeeds" do
      before do
        allow(create_upload).to receive(:call).and_return(Success({upload:, generation:, map:}))
      end

      it "returns 201 with upload, map, and generation ULIDs" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(201)
        expect(response).to conform_to_openapi("POST /api/v1/uploads")
        body = JSON.parse(response.body.join)
        expect(body).to include("ulid" => "01UPLOAD", "map_ulid" => "01MAP", "generation_ulid" => "01GEN")
      end

      it "passes the metadata to the operation as parsed, with string keys" do
        metadata = {"map_id" => "ae8ec3ab", "unique_id" => "550f41a9", "tick" => 1000, "surfaces" => [{"name" => "nauvis"}]}

        action.call(session.merge(metadata:, total_image_count: 5, name: "My Map"))

        expect(create_upload).to have_received(:call).with(hash_including(metadata:))
      end

      it "passes name to the operation" do
        action.call(session.merge(action_params))

        expect(create_upload).to have_received(:call).with(hash_including(name: "My Map"))
      end

      it "returns 400 when name is not provided" do
        response = action.call(session.merge(action_params.except(:name)))

        expect(response.status).to eq(400)
        expect(response).to conform_to_openapi("POST /api/v1/uploads")
        expect(create_upload).not_to have_received(:call)
      end

      it "returns 400 when name is empty" do
        response = action.call(session.merge(action_params.merge(name: "")))

        expect(response.status).to eq(400)
        expect(response).to conform_to_openapi("POST /api/v1/uploads")
        expect(create_upload).not_to have_received(:call)
      end

      it "passes the name to the operation without leading and trailing whitespace" do
        action.call(session.merge(action_params.merge(name: "  My Map  ")))

        expect(create_upload).to have_received(:call).with(hash_including(name: "My Map"))
      end

      it "returns 400 when name is only whitespace" do
        response = action.call(session.merge(action_params.merge(name: "   ")))

        expect(response.status).to eq(400)
        expect(response).to conform_to_openapi("POST /api/v1/uploads")
        expect(create_upload).not_to have_received(:call)
      end

      it "returns 400 when total_image_count is a string" do
        response = action.call(session.merge(action_params.merge(total_image_count: "5")))

        expect(response.status).to eq(400)
        expect(response).to conform_to_openapi("POST /api/v1/uploads")
        expect(create_upload).not_to have_received(:call)
      end

      it "returns 400 when total_image_count is a float" do
        response = action.call(session.merge(action_params.merge(total_image_count: 5.0)))

        expect(response.status).to eq(400)
        expect(response).to conform_to_openapi("POST /api/v1/uploads")
        expect(create_upload).not_to have_received(:call)
      end

      it "returns 400 when total_image_count is out of range" do
        [0, 10_001].each do |total_image_count|
          response = action.call(session.merge(action_params.merge(total_image_count:)))

          expect(response.status).to eq(400)
          expect(response).to conform_to_openapi("POST /api/v1/uploads")
        end
        expect(create_upload).not_to have_received(:call)
      end
    end

    context "when the operation returns a conflict failure" do
      before { allow(create_upload).to receive(:call).and_return(Failure(:conflict)) }

      it "returns 409" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(409)
        expect(response).to conform_to_openapi("POST /api/v1/uploads")
      end
    end

    context "when the operation rejects the name" do
      before { allow(create_upload).to receive(:call).and_return(Failure([:invalid, "error-map-name-too-long"])) }

      it "returns 422 with the error key" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(422)
        expect(response).to conform_to_openapi("POST /api/v1/uploads")
        expect(JSON.parse(response.body.join)).to eq({"error" => "error-map-name-too-long"})
      end
    end

    context "when metadata fields are invalid" do
      before { allow(create_upload).to receive(:call) }

      it "returns 400 for invalid map_id without calling the operation" do
        params = action_params.merge(metadata: action_params[:metadata].merge("map_id" => "xyz!"))
        response = action.call(session.merge(params))
        expect(response.status).to eq(400)
        expect(response).to conform_to_openapi("POST /api/v1/uploads")
        expect(create_upload).not_to have_received(:call)
      end

      it "returns 400 for invalid unique_id without calling the operation" do
        params = action_params.merge(metadata: action_params[:metadata].merge("unique_id" => "xyz!"))
        response = action.call(session.merge(params))
        expect(response.status).to eq(400)
        expect(response).to conform_to_openapi("POST /api/v1/uploads")
        expect(create_upload).not_to have_received(:call)
      end

      it "returns 400 for non-integer tick without calling the operation" do
        params = action_params.merge(metadata: action_params[:metadata].merge("tick" => "abc"))
        response = action.call(session.merge(params))
        expect(response.status).to eq(400)
        expect(response).to conform_to_openapi("POST /api/v1/uploads")
        expect(create_upload).not_to have_received(:call)
      end

      it "returns 400 for a tick given as a string without calling the operation" do
        params = action_params.merge(metadata: action_params[:metadata].merge("tick" => "1000"))
        response = action.call(session.merge(params))
        expect(response.status).to eq(400)
        expect(response).to conform_to_openapi("POST /api/v1/uploads")
        expect(create_upload).not_to have_received(:call)
      end

      it "returns 400 for a negative tick without calling the operation" do
        params = action_params.merge(metadata: action_params[:metadata].merge("tick" => -1))
        response = action.call(session.merge(params))
        expect(response.status).to eq(400)
        expect(response).to conform_to_openapi("POST /api/v1/uploads")
        expect(create_upload).not_to have_received(:call)
      end

      it "returns 400 for tick exceeding uint32 max without calling the operation" do
        params = action_params.merge(metadata: action_params[:metadata].merge("tick" => 4_294_967_296))
        response = action.call(session.merge(params))
        expect(response.status).to eq(400)
        expect(response).to conform_to_openapi("POST /api/v1/uploads")
        expect(create_upload).not_to have_received(:call)
      end
    end

    context "when the operation returns an S3 error failure" do
      before { allow(create_upload).to receive(:call).and_return(Failure(:s3_error)) }

      it "returns 502" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(502)
        expect(response).to conform_to_openapi("POST /api/v1/uploads")
      end
    end
  end
end
