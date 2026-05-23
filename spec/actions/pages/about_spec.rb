# frozen_string_literal: true

RSpec.describe PastaAtlas::Actions::Pages::About, :action_env do
  let(:action) { PastaAtlas::Actions::Pages::About.new }

  it "returns 200" do
    response = action.call(locale_env)

    expect(response.status).to eq(200)
  end
end
