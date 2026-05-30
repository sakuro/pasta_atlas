# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Uploads::PresignedUrls::Create, :db do
  let(:issue_presigned_urls) { instance_double(PastaAtlas::Operations::Uploads::IssuePresignedUrls) }
  let(:user_repo) { instance_double(PastaAtlas::Repos::UserRepo) }
  let(:action) { PastaAtlas::Actions::Uploads::PresignedUrls::Create.new(issue_presigned_urls:, user_repo:) }

  let(:filenames) { ["s1zoom_4/tile_0_0.jpg", "s1zoom_4/tile_0_1.jpg"] }
  let(:session) { {"rack.session" => {"user_id" => 1}} }
  let(:action_params) { {ulid: "01UPLOAD", filenames:} }

  context "when no session" do
    let(:guest_user) { double("User", id: 99) }

    before do
      allow(user_repo).to receive(:find_by_name).with("guest").and_return(guest_user)
      allow(issue_presigned_urls).to receive(:call).and_return(Success({}))
    end

    it "allows guest requests" do
      response = action.call({"rack.session" => {}}.merge(action_params))

      expect(response.status).to eq(200)
      expect(issue_presigned_urls).to have_received(:call).with(upload_ulid: "01UPLOAD", filenames:, user_id: 99)
    end
  end

  context "when authenticated" do
    context "when the operation succeeds" do
      let(:presigned_urls) { {"s1zoom_4/tile_0_0.jpg" => "https://s3.example/0", "s1zoom_4/tile_0_1.jpg" => "https://s3.example/1"} }

      before { allow(issue_presigned_urls).to receive(:call).and_return(Success(presigned_urls)) }

      it "returns 200 with presigned URLs" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(200)
        body = JSON.parse(response.body.join)
        expect(body["presigned_urls"].keys).to match_array(filenames)
      end
    end

    context "when the upload is not found" do
      before { allow(issue_presigned_urls).to receive(:call).and_return(Failure(:not_found)) }

      it "returns 404" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(404)
      end
    end

    context "when the upload is not processable" do
      before { allow(issue_presigned_urls).to receive(:call).and_return(Failure(:unprocessable_entity)) }

      it "returns 422" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(422)
      end
    end

    context "when the upload belongs to another user" do
      before { allow(issue_presigned_urls).to receive(:call).and_return(Failure(:forbidden)) }

      it "returns 403" do
        response = action.call(session.merge(action_params))

        expect(response.status).to eq(403)
      end
    end
  end
end
