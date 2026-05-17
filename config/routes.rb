# frozen_string_literal: true

module PastaAtlas
  class Routes < Hanami::Routes
    root to: "maps.index"
    get "/@:user_name/maps/:ulid", to: "maps.viewer"

    get "/@:user_name", to: "user.show"
    get "/@:user_name/edit", to: "user.edit"
    patch "/@:user_name/profile", to: "user.profile.update"
    patch "/@:user_name/preferences", to: "user.preferences.update"
    patch "/@:user_name/avatar", to: "user.avatar.update"
    delete "/@:user_name/avatar", to: "user.avatar.destroy"
    delete "/@:user_name/credentials/:provider", to: "user.credentials.destroy"

    get "/auth/discord/callback", to: "auth.discord.callback"
    get "/auth/github/callback", to: "auth.github.callback"
    get "/auth/failure", to: "auth.failure"
    get "/auth/register", to: "auth.registrations.new"
    post "/auth/register", to: "auth.registrations.create"
    delete "/auth/session", to: "auth.session.destroy"

    get "/api/v1/maps/:ulid", to: "maps.show"
    patch "/api/v1/maps/:ulid/name", to: "maps.update_name"
    post "/api/v1/profile/avatar_presigned_url", to: "user.avatar_presigned_url.create"
    post "/api/v1/uploads", to: "uploads.create"
    post "/api/v1/uploads/:ulid/presigned_urls", to: "uploads.presigned_urls.create"
    patch "/api/v1/uploads/:ulid", to: "uploads.update"
  end
end
