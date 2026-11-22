# frozen_string_literal: true

RSpec.describe PastaAtlas::AvatarPolicy do
  describe ".signature?" do
    let(:jpeg) { "\xFF\xD8\xFF\xE0\x00\x10JFIF".b }
    let(:png) { "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR".b }
    let(:webp) { "RIFF\x24\x00\x00\x00WEBPVP8 ".b }

    it "accepts the signature of each allowed type" do
      expect(PastaAtlas::AvatarPolicy.signature?("image/jpeg", jpeg)).to be(true)
      expect(PastaAtlas::AvatarPolicy.signature?("image/png", png)).to be(true)
      expect(PastaAtlas::AvatarPolicy.signature?("image/webp", webp)).to be(true)
    end

    it "rejects a signature that belongs to another type" do
      expect(PastaAtlas::AvatarPolicy.signature?("image/png", jpeg)).to be(false)
      expect(PastaAtlas::AvatarPolicy.signature?("image/webp", png)).to be(false)
    end

    it "rejects content that is not an image" do
      expect(PastaAtlas::AvatarPolicy.signature?("image/png", "<!doctype html>")).to be(false)
      expect(PastaAtlas::AvatarPolicy.signature?("image/webp", "RIFF\x00\x00\x00\x00WAVE".b)).to be(false)
    end

    it "rejects a header that is empty" do
      expect(PastaAtlas::AvatarPolicy.signature?("image/jpeg", "")).to be(false)
    end
  end
end
