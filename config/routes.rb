# frozen_string_literal: true

module PastaAtlas
  class Routes < Hanami::Routes
    root to: "spa.shell"

    get "/up", to: ->(_env) { [200, {"content-type" => "text/plain"}, ["OK"]] }

    get "/about", to: "spa.shell", as: :about
    get "/privacy", to: "spa.shell", as: :privacy_policy
    get "/terms", to: "spa.shell", as: :terms_of_service
    get "/@:user_name/maps/:ulid", to: "spa.shell", as: :map_viewer
    post "/maps/:ulid/deletion_requests", to: "maps.deletion_requests.create"

    get "/@:user_name", to: "spa.shell", as: :user
    get "/@:user_name/maps", to: "user.maps.index"
    get "/@:user_name/profile", to: "user.profile.show"
    patch "/@:user_name/profile", to: "user.profile.update", as: :user_profile
    get "/@:user_name/preferences", to: "user.preferences.show"
    patch "/@:user_name/preferences", to: "user.preferences.update", as: :user_preferences
    patch "/@:user_name/avatar", to: "user.avatar.update"
    delete "/@:user_name/avatar", to: "user.avatar.destroy"
    get "/@:user_name/credentials", to: "user.credentials.index"
    delete "/@:user_name/credentials/:provider", to: "user.credentials.destroy", as: :user_credential
    delete "/@:user_name", to: "user.destroy"

    get "/auth/discord/callback", to: "auth.discord.callback"
    get "/auth/github/callback", to: "auth.github.callback"
    post "/auth/steam/callback", to: "auth.steam.callback"
    get "/auth/failure", to: "auth.failure"
    get "/auth/register", to: "spa.shell", as: :auth_registrations
    post "/auth/register", to: "auth.registrations.create"
    delete "/auth/session", to: "auth.session.destroy", as: :auth_session

    get "/api/v1/auth/current", to: "api.auth.current"
    get "/api/v1/auth/registration", to: "api.auth.registration"
    get "/api/v1/pages/:slug", to: "api.pages.show"

    get "/api/v1/maps", to: "maps.index"
    get "/api/v1/users/:name", to: "api.users.show"
    get "/api/v1/maps/lookup", to: "maps.lookup"
    get "/api/v1/maps/:ulid", to: "maps.show"
    patch "/api/v1/maps/:ulid/name", to: "maps.update_name"
    post "/api/v1/profile/avatar_presigned_url", to: "user.avatar_presigned_url.create"
    post "/api/v1/uploads", to: "uploads.create"
    post "/api/v1/uploads/:ulid/presigned_urls", to: "uploads.presigned_urls.create"
    patch "/api/v1/uploads/:ulid", to: "uploads.update"
  end
end
