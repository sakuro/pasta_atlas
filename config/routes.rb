# frozen_string_literal: true

module PastaAtlas
  class Routes < Hanami::Routes
    root to: "spa.shell"

    get "/up", to: ->(_env) { [200, {"content-type" => "text/plain"}, ["OK"]] }

    get "/about",         to: "spa.shell"
    get "/auth/register", to: "spa.shell"
    get "/privacy",       to: "spa.shell"
    get "/terms",         to: "spa.shell"
    get "/@:user_name",    to: "spa.user"
    get "/maps/:map_ulid", to: "spa.map_viewer"

    get "/api/v1/auth/current",                            to: "api.auth.current"
    get "/api/v1/auth/registration",                       to: "api.auth.registration"

    get "/api/v1/maps",                                    to: "api.maps.index"
    get "/api/v1/maps/:ulid",                              to: "api.maps.show"
    post "/api/v1/maps/:ulid/deletion_requests", to: "api.maps.deletion_requests.create"
    patch "/api/v1/maps/:ulid/name", to: "api.maps.update_name"
    get "/api/v1/maps/lookup",                             to: "api.maps.lookup"

    get "/api/v1/pages/:slug",                             to: "api.pages.show"

    post "/api/v1/uploads", to: "api.uploads.create"
    patch "/api/v1/uploads/:ulid", to: "api.uploads.update"
    post "/api/v1/uploads/:ulid/presigned_posts", to: "api.uploads.presigned_posts.create"
    post "/api/v1/uploads/:ulid/verify_batch", to: "api.uploads.verify_batches.create"

    get "/api/v1/users/:name", to: "api.users.show"
    delete "/api/v1/users/:user_name", to: "api.users.destroy"
    patch "/api/v1/users/:user_name/avatar", to: "api.users.avatar.update"
    delete "/api/v1/users/:user_name/avatar", to: "api.users.avatar.destroy"
    get "/api/v1/users/:user_name/credentials", to: "api.users.credentials.index"
    delete "/api/v1/users/:user_name/credentials/:provider", to: "api.users.credentials.destroy"
    get "/api/v1/users/:user_name/maps",                  to: "api.users.maps.index"
    get "/api/v1/users/:user_name/preferences",           to: "api.users.preferences.show"
    patch "/api/v1/users/:user_name/preferences", to: "api.users.preferences.update"
    post "/api/v1/users/:user_name/profile/avatar_presigned_url", to: "api.users.profile.avatar_presigned_url.create"
    get "/api/v1/users/:user_name/profile", to: "api.users.profile.show"
    patch "/api/v1/users/:user_name/profile", to: "api.users.profile.update"

    get "/auth/discord/callback",                         to: "auth.discord.callback"
    get "/auth/failure",                                  to: "auth.failure"
    get "/auth/github/callback",                          to: "auth.github.callback"
    post "/auth/register", to: "auth.registrations.create"
    delete "/auth/session", to: "auth.session.destroy"
    post "/auth/steam/callback", to: "auth.steam.callback"

    get "/*path", to: "spa.not_found"
  end
end
