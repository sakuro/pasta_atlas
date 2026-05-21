# frozen_string_literal: true

RSpec.describe PastaAtlas::Views::Pages::About do
  let(:view) { PastaAtlas::Views::Pages::About.new }

  def render(locale_tags:)
    view.call(layout: false, locale_tags:).to_s
  end

  it "renders the Japanese partial when ja is requested" do
    html = render(locale_tags: %w[ja en])

    expect(html).to include("<h1>このサイトについて</h1>")
  end

  it "falls back to the English partial when no partial exists for the requested locale" do
    html = render(locale_tags: %w[und en])

    expect(html).to include("<h1>About PastaAtlas</h1>")
  end
end
