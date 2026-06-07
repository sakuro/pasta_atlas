# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Uploads::PresignedPosts::Create, :db do
  let(:issue_presigned_posts) { instance_double(PastaAtlas::Operations::Uploads::IssuePresignedPosts) }
  let(:guest) { double("User", id: 99) }
  let(:action) { PastaAtlas::Actions::API::Uploads::PresignedPosts::Create.new(issue_presigned_posts:, guest:) }

  let(:filenames) { ["s1zoom_4/tile_0_0.jpg", "s1zoom_4/tile_0_1.jpg"] }
  let(:session) { {"rack.session" => {"user_id" => 1}} }
  let(:action_params) { {ulid: "01UPLOAD", filenames:} }

  context "when no session" do
    before do
      allow(issue_presigned_posts).to receive(:call).and_return(Success({}))
    end

    it "allows guest requests" do
      response = action.call({"rack.session" => {}}.merge(action_params))

      expect(response.status).to eq(200)
      expect(issue_presigned_posts).to have_received(:call).with(upload_ulid: "01UPLOAD", filenames:, user_id: 99)
    end
  end

  context "when authenticated" do
    context "when the operation succeeds" do
      let(:presigned_posts) do
        {
          "s1zoom_4/tile_0_0.jpg" => {url: "https://s3.example/", fields: {"key" => "path/0"}},
          "s1zoom_4/tile_0_1.jpg" => {url: "https://s3.example/", fields: {"key" => "path/1"}}
        }
      end

      before { allow(issue_presigned_posts).to receive(:call).and_return(Success(presigned_posts)) }

      it "returns 200 with presigned POST entries" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(200)
        body = JSON.parse(response.body.join)
        expect(body["presigned_posts"].keys).to match_array(filenames)
      end
    end

    context "when filenames are invalid" do
      before { allow(issue_presigned_posts).to receive(:call) }

      it "returns 400 for a path traversal attempt without calling the operation" do
        response = action.call(session.merge(ulid: "01UPLOAD", filenames: ["../../other/file.jpg"]))
        expect(response.status).to eq(400)
        expect(issue_presigned_posts).not_to have_received(:call)
      end

      it "returns 400 for a filename not matching the tile pattern without calling the operation" do
        response = action.call(session.merge(ulid: "01UPLOAD", filenames: ["mapshot.json"]))
        expect(response.status).to eq(400)
        expect(issue_presigned_posts).not_to have_received(:call)
      end
    end

    context "when the upload is not found" do
      before { allow(issue_presigned_posts).to receive(:call).and_return(Failure(:not_found)) }

      it "returns 404" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(404)
      end
    end

    context "when the upload is not processable" do
      before { allow(issue_presigned_posts).to receive(:call).and_return(Failure(:unprocessable_entity)) }

      it "returns 422" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(422)
      end
    end

    context "when the upload belongs to another user" do
      before { allow(issue_presigned_posts).to receive(:call).and_return(Failure(:forbidden)) }

      it "returns 403" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(403)
      end
    end
  end
end
