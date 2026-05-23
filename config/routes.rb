# frozen_string_literal: true

module PastaAtlas
  class Routes < Hanami::Routes
    root to: "maps.index"

    get "/about", to: "pages.about", as: :about
    get "/privacy", to: "pages.privacy_policy", as: :privacy_policy
    get "/terms", to: "pages.terms_of_service", as: :terms_of_service
    get "/@:user_name/maps/:ulid", to: "maps.viewer", as: :map_viewer
    post "/maps/:ulid/deletion_requests", to: "maps.deletion_requests.create"

    get "/@:user_name", to: "user.show", as: :user
    patch "/@:user_name/profile", to: "user.profile.update", as: :user_profile
    patch "/@:user_name/preferences", to: "user.preferences.update", as: :user_preferences
    patch "/@:user_name/avatar", to: "user.avatar.update"
    delete "/@:user_name/avatar", to: "user.avatar.destroy"
    delete "/@:user_name/credentials/:provider", to: "user.credentials.destroy", as: :user_credential
    delete "/@:user_name", to: "user.destroy"

    get "/auth/discord/callback", to: "auth.discord.callback"
    get "/auth/github/callback", to: "auth.github.callback"
    post "/auth/steam/callback", to: "auth.steam.callback"
    get "/auth/failure", to: "auth.failure"
    get "/auth/register", to: "auth.registrations.new", as: :auth_registrations
    post "/auth/register", to: "auth.registrations.create"
    delete "/auth/session", to: "auth.session.destroy", as: :auth_session

    get "/api/v1/maps/lookup", to: "maps.lookup"
    get "/api/v1/maps/:ulid", to: "maps.show"
    patch "/api/v1/maps/:ulid/name", to: "maps.update_name"
    post "/api/v1/profile/avatar_presigned_url", to: "user.avatar_presigned_url.create"
    post "/api/v1/uploads", to: "uploads.create"
    post "/api/v1/uploads/:ulid/presigned_urls", to: "uploads.presigned_urls.create"
    patch "/api/v1/uploads/:ulid", to: "uploads.update"
  end
end
