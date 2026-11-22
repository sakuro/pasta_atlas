# frozen_string_literal: true

require "tmpdir"
require_relative "../../../lib/pasta_atlas/factorio_icon_importer"

RSpec.describe PastaAtlas::FactorioIconImporter do
  let(:root) { Pathname(Dir.mktmpdir) }
  let(:source) { root.join("script-output") }
  let(:destination) { root.join("factorio-icons") }

  after { FileUtils.rm_rf(root) }

  def write(path, content="png")
    FileUtils.mkdir_p(path.dirname)
    File.binwrite(path, content)
  end

  it "replaces the destination with the sprite directories of the source" do
    write(destination.join("item/old.png"))
    write(destination.join("gone/old.png"))
    write(source.join("item/iron-plate.png"), "new")
    write(source.join("virtual-signal/signal-A.png"))

    result = PastaAtlas::FactorioIconImporter.new(destination:).call(source)

    expect(destination.glob("*/*").map {|path| path.relative_path_from(destination).to_s }).to contain_exactly("item/iron-plate.png", "virtual-signal/signal-A.png")
    expect(destination.join("item/iron-plate.png").binread).to eq("new")
    expect(result).to eq(PastaAtlas::FactorioIconImporter::Result[types: 2, sprites: 2, previous_sprites: 2])
  end

  it "ignores directories without PNG files directly in them and files that are not PNG" do
    write(source.join("item/iron-plate.png"))
    write(source.join("item/notes.txt"))
    write(source.join("mapshot/map-1234/tile.png"))
    write(source.join("mod-settings-dump.json"))

    PastaAtlas::FactorioIconImporter.new(destination:).call(source)

    expect(destination.glob("**/*").filter_map {|path| path.relative_path_from(destination).to_s if path.file? }).to eq(["item/iron-plate.png"])
  end

  it "keeps the destination and raises when the source has no sprites" do
    write(destination.join("item/old.png"))
    write(source.join("mod-settings-dump.json"))

    expect { PastaAtlas::FactorioIconImporter.new(destination:).call(source) }.to raise_error(PastaAtlas::FactorioIconImporter::NoSpritesError)
    expect(destination.join("item/old.png")).to exist
  end

  it "does not carry over the permissions of the source" do
    write(source.join("item/iron-plate.png"))
    source.join("item/iron-plate.png").chmod(0777)

    PastaAtlas::FactorioIconImporter.new(destination:).call(source)

    expect(destination.join("item/iron-plate.png").stat.mode & 0111).to eq(0)
  end

  it "creates the destination when it does not exist yet" do
    write(source.join("item/iron-plate.png"))

    result = PastaAtlas::FactorioIconImporter.new(destination:).call(source)

    expect(result.previous_sprites).to eq(0)
    expect(destination.join("item/iron-plate.png")).to exist
  end
end
