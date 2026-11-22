# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::API::Users::Profile::AvatarPresignedPost::Create do
  let(:verify_ownership) { instance_double(PastaAtlas::Operations::User::VerifyOwnership) }
  let(:create_avatar_presigned_post) { instance_double(PastaAtlas::Operations::User::AvatarPresignedPost::Create) }
  let(:user_resolver) { instance_double(PastaAtlas::Resolvers::UserResolver) }
  let(:action) do
    PastaAtlas::Actions::API::Users::Profile::AvatarPresignedPost::Create.new(
      verify_ownership:, create_avatar_presigned_post:, user_resolver:
    )
  end

  let(:user) { double("User", id: 1, name: "wube") }
  let(:env) { {"rack.session" => {"user_id" => 1}, :user_name => "wube", :content_type => "image/png"} }

  before { allow(user_resolver).to receive(:call).with(1).and_return(user) }

  context "when the user owns the profile" do
    let(:presigned_post) { {url: "https://s3.example/", fields: {"key" => "wube/avatar/01HXY.png"}} }

    before do
      allow(verify_ownership).to receive(:call).with(current_user: user, user_name: "wube").and_return(Success(user))
      allow(create_avatar_presigned_post).to receive(:call)
        .with(user_id: 1, content_type: "image/png")
        .and_return(Success({presigned_post:, s3_key: "wube/avatar/01HXY.png"}))
    end

    it "returns 200 with the presigned POST and the S3 key" do
      response = action.call(env)

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body.join)).to eq(
        "presigned_post" => {"url" => "https://s3.example/", "fields" => {"key" => "wube/avatar/01HXY.png"}},
        "s3_key" => "wube/avatar/01HXY.png"
      )
    end
  end

  context "when the user does not own the profile" do
    before do
      allow(verify_ownership).to receive(:call).and_return(Failure(:forbidden))
      allow(create_avatar_presigned_post).to receive(:call)
    end

    it "returns 403 without issuing a presigned POST" do
      response = action.call(env)

      expect(response.status).to eq(403)
      expect(create_avatar_presigned_post).not_to have_received(:call)
    end
  end

  context "when the content type is unsupported" do
    before { allow(verify_ownership).to receive(:call) }

    it "returns 400" do
      response = action.call(env.merge(content_type: "image/gif"))

      expect(response.status).to eq(400)
      expect(verify_ownership).not_to have_received(:call)
    end
  end
end
