# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Uploads::Create, :db do
  let(:create_upload) { instance_double(PastaAtlas::Operations::Uploads::Create) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:action) do
    PastaAtlas::Actions::Uploads::Create.new(create_upload:, user_repo:)
  end

  let(:session) { {"rack.session" => {"user_id" => 1}} }
  let(:action_params) do
    {metadata: {map_id: "ae8ec3ab", unique_id: "550f41a9", tick: "1000"}, total_image_count: 5}
  end
  let(:action_params_with_name) { action_params.merge(name: "My Map") }

  let(:upload) { double("Upload", ulid: "01UPLOAD") }
  let(:generation) { double("Generation", ulid: "01GEN") }
  let(:map) { double("Map", ulid: "01MAP") }

  context "when no session" do
    let(:guest_user) { double("User", id: 99) }

    before do
      allow(user_repo).to receive(:find_by_name).with("guest").and_return(guest_user)
      allow(create_upload).to receive(:call).and_return(Success({upload:, generation:, map:}))
    end

    it "uses the guest user" do
      response = action.call({"rack.session" => {}}.merge(action_params))

      expect(response.status).to eq(201)
      expect(create_upload).to have_received(:call).with(hash_including(user_id: 99))
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
        body = JSON.parse(response.body.join)
        expect(body).to include("ulid" => "01UPLOAD", "map_ulid" => "01MAP", "generation_ulid" => "01GEN")
      end

      it "passes name to the operation when provided" do
        action.call(session.merge(action_params_with_name))

        expect(create_upload).to have_received(:call).with(hash_including(name: "My Map"))
      end

      it "passes nil name to the operation when not provided" do
        action.call(session.merge(action_params))

        expect(create_upload).to have_received(:call).with(hash_including(name: nil))
      end

      it "passes nil name to the operation when name is empty" do
        action.call(session.merge(action_params.merge(name: "")))

        expect(create_upload).to have_received(:call).with(hash_including(name: nil))
      end
    end

    context "when the operation returns a conflict failure" do
      before { allow(create_upload).to receive(:call).and_return(Failure(:conflict)) }

      it "returns 409" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(409)
      end
    end

    context "when metadata fields are invalid" do
      before { allow(create_upload).to receive(:call) }

      it "returns 400 for invalid map_id without calling the operation" do
        params = action_params.merge(metadata: action_params[:metadata].merge(map_id: "xyz!"))
        response = action.call(session.merge(params))
        expect(response.status).to eq(400)
        expect(create_upload).not_to have_received(:call)
      end

      it "returns 400 for invalid unique_id without calling the operation" do
        params = action_params.merge(metadata: action_params[:metadata].merge(unique_id: "xyz!"))
        response = action.call(session.merge(params))
        expect(response.status).to eq(400)
        expect(create_upload).not_to have_received(:call)
      end

      it "returns 400 for non-integer tick without calling the operation" do
        params = action_params.merge(metadata: action_params[:metadata].merge(tick: "abc"))
        response = action.call(session.merge(params))
        expect(response.status).to eq(400)
        expect(create_upload).not_to have_received(:call)
      end

      it "returns 400 for tick exceeding uint32 max without calling the operation" do
        params = action_params.merge(metadata: action_params[:metadata].merge(tick: 4_294_967_296))
        response = action.call(session.merge(params))
        expect(response.status).to eq(400)
        expect(create_upload).not_to have_received(:call)
      end
    end

    context "when the operation returns an S3 error failure" do
      before { allow(create_upload).to receive(:call).and_return(Failure(:s3_error)) }

      it "returns 502" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(502)
      end
    end
  end
end
