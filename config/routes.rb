# frozen_string_literal: true

module PastaAtlas
  class Routes < Hanami::Routes
    post "/api/v1/uploads", to: "uploads.create"
    post "/api/v1/uploads/:ulid/presigned_urls", to: "uploads.presigned_urls.create"
    patch "/api/v1/uploads/:ulid", to: "uploads.update"
  end
end
