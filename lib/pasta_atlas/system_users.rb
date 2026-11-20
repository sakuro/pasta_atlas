# frozen_string_literal: true

module PastaAtlas
  # Accounts the application owns. The seeds create SEEDED; the avatar objects are created by
  # Terraform (terraform/environments/*/s3.tf) under the same keys.
  module SystemUsers
    Definition = Data.define(:name, :display_name, :avatar_s3_key)

    SEEDED = [
      Definition[name: "guest", display_name: "Guest", avatar_s3_key: "guest/avatar/guest.png"],
      Definition[name: "compilatron", display_name: "Compilatron", avatar_s3_key: "compilatron/avatar/compilatron.png"]
    ].freeze
    public_constant :SEEDED

    # `api` and `admin` have no account; nobody can register under these names.
    RESERVED_NAMES = [*SEEDED.map(&:name), "api", "admin"].freeze
    public_constant :RESERVED_NAMES
  end
end
