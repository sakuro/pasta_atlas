# frozen_string_literal: true

module PastaAtlas
  class Routes < Hanami::Routes
    root to: "maps.index"
    get "/@:user_name/maps/:ulid", to: "maps.viewer"

    get "/@:user_name/profile", to: "profile.show"
    get "/@:user_name/profile/edit", to: "profile.edit"
    patch "/@:user_name/profile", to: "profile.update"
    patch "/@:user_name/profile/avatar", to: "profile.avatar.update"
    delete "/@:user_name/profile/avatar", to: "profile.avatar.destroy"

    get "/auth/github/callback", to: "auth.github.callback"
    get "/auth/failure", to: "auth.failure"
    get "/auth/register", to: "auth.registrations.new"
    post "/auth/register", to: "auth.registrations.create"
    delete "/auth/session", to: "auth.session.destroy"

    get "/api/v1/maps/:ulid", to: "maps.show"
    post "/api/v1/profile/avatar_presigned_url", to: "profile.avatar_presigned_url.create"
    post "/api/v1/uploads", to: "uploads.create"
    post "/api/v1/uploads/:ulid/presigned_urls", to: "uploads.presigned_urls.create"
    patch "/api/v1/uploads/:ulid", to: "uploads.update"
  end
end
