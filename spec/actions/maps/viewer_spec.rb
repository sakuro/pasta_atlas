# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Maps::Viewer, :action_env do
  let(:find_by_id) { instance_double(PastaAtlas::Operations::User::FindById) }
  let(:show_map) { instance_double(PastaAtlas::Operations::Maps::Show) }
  let(:settings) { double("Settings", cloudfront_base_url: "https://cdn.example.com") }
  let(:action) { PastaAtlas::Actions::Maps::Viewer.new(find_by_id:, show_map:, settings:) }

  let(:action_params) { locale_env.merge(ulid: "01MAP") }

  context "when the map is found" do
    let(:map) { double("Map", ulid: "01MAP", display_name: "My Map", user_id: 1) }
    let(:user) { double("User", id: 1, name: "sakuro") }
    let(:profile) { double("UserProfile", display_name: "Sakuro", avatar_s3_key: nil) }
    let(:generation) { double("Generation", ulid: "01GEN", tick: 1000, metadata_s3_key: "key", created_at: Time.now) }

    before do
      allow(show_map).to receive(:call).and_return(
        Success({map:, user:, profile:, generations: [generation]})
      )
    end

    context "when the viewer is not logged in" do
      it "returns 200" do
        response = action.call(action_params)

        expect(response.status).to eq(200)
      end
    end

    context "when the viewer is logged in" do
      let(:viewer) { double("User", name: "alice") }
      let(:env) { action_params.merge("rack.session" => {user_id: 2}) }

      before { allow(find_by_id).to receive(:call).with(user_id: 2).and_return(Success(viewer)) }

      it "returns 200" do
        response = action.call(env)

        expect(response.status).to eq(200)
      end
    end
  end

  context "when the map is not found" do
    before { allow(show_map).to receive(:call).and_return(Failure(:not_found)) }

    it "returns 404" do
      response = action.call(action_params)

      expect(response.status).to eq(404)
    end
  end
end
