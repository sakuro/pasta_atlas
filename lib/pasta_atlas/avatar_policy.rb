# frozen_string_literal: true

module PastaAtlas
  # What an avatar image may be. The presigned POST enforces the size and type while the file is
  # uploaded, and Operations::User::Avatar::VerifyUpload checks the stored object against the same rules.
  module AvatarPolicy
    CONTENT_TYPES = {
      "image/jpeg" => "jpg",
      "image/png" => "png",
      "image/webp" => "webp"
    }.freeze
    public_constant :CONTENT_TYPES

    # Keep in sync with MAX_BYTES in frontend/pages/user/AvatarUpload.tsx.
    MAX_SIZE_BYTES = 5 * 1024 * 1024
    public_constant :MAX_SIZE_BYTES

    # Issued keys that were not applied yet; a user cannot request more until they expire.
    MAX_PENDING_UPLOADS = 10
    public_constant :MAX_PENDING_UPLOADS

    # Enough bytes to tell the formats apart: the WebP signature ends at the twelfth.
    SIGNATURE_LENGTH = 12
    public_constant :SIGNATURE_LENGTH

    SIGNATURES = {
      "image/jpeg" => /\A\xFF\xD8\xFF/n,
      "image/png" => /\A\x89PNG\r\n\x1A\n/n,
      "image/webp" => /\ARIFF.{4}WEBP/mn
    }.freeze
    private_constant :SIGNATURES

    def self.signature?(content_type, header) = SIGNATURES[content_type]&.match?(header.b) || false
  end
end
