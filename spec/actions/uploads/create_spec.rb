# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Uploads::Create, :db do
  let(:create_upload) { instance_double(PastaAtlas::Operations::Uploads::Create) }
  let(:generation_repo) { instance_double(PastaAtlas::Repos::GenerationRepo) }
  let(:map_repo) { instance_double(PastaAtlas::Repos::MapRepo) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:action) do
    PastaAtlas::Actions::Uploads::Create.new(
      create_upload:,
      generation_repo:,
      map_repo:,
      user_repo:
    )
  end

  let(:session) { {"rack.session" => {"user_id" => 1}} }
  let(:action_params) do
    {metadata: {map_id: "ae8ec3ab", unique_id: "550f41a9", tick: "1000"}, total_image_count: 5}
  end

  context "when no session and no guest user" do
    before { allow(user_repo).to receive(:find_by_name).with("guest").and_return(nil) }

    it "returns 401" do
      response = action.call({"rack.session" => {}}.merge(action_params))

      expect(response.status).to eq(401)
    end
  end

  context "when authenticated" do
    context "when the operation succeeds" do
      let(:upload) { double("Upload", ulid: "01UPLOAD", generation_id: 42) }
      let(:generation) { double("Generation", ulid: "01GEN", map_id: 7) }
      let(:map) { double("Map", ulid: "01MAP") }

      before do
        allow(create_upload).to receive(:call).and_return(Success(upload))
        allow(generation_repo).to receive(:find_by_id).with(42).and_return(generation)
        allow(map_repo).to receive(:find_by_id).with(7).and_return(map)
      end

      it "returns 201 with upload, map, and generation ULIDs" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(201)
        body = JSON.parse(response.body.join)
        expect(body).to include("ulid" => "01UPLOAD", "map_ulid" => "01MAP", "generation_ulid" => "01GEN")
      end
    end

    context "when the operation returns a conflict failure" do
      before { allow(create_upload).to receive(:call).and_return(Failure(:conflict)) }

      it "returns 409" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(409)
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
