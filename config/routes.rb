# frozen_string_literal: true

module PastaAtlas
  class Routes < Hanami::Routes
    root to: "maps.index"
    get "/@:user_profile_name/maps/:ulid", to: "maps.viewer"

    get "/auth/github/callback", to: "auth.github.callback"
    get "/auth/failure", to: "auth.failure"
    get "/auth/register", to: "auth.registrations.new"
    post "/auth/register", to: "auth.registrations.create"
    delete "/auth/session", to: "auth.session.destroy"

    get "/api/v1/maps/:ulid", to: "maps.show"
    post "/api/v1/uploads", to: "uploads.create"
    post "/api/v1/uploads/:ulid/presigned_urls", to: "uploads.presigned_urls.create"
    patch "/api/v1/uploads/:ulid", to: "uploads.update"
  end
end
