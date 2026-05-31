# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Maps
      class Show < PastaAtlas::Action
        include Deps[
          "settings",
          show_map: "operations.maps.show"
        ]

        def handle(request, response)
          result = show_map.call(ulid: request.params[:ulid])
          case result
          in Success({map:, user:, profile:, updated_at:, generations:})
            avatar_url = profile.avatar_s3_key ? "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}" : nil
            json_response(response, {
              ulid: map.ulid,
              display_name: map.display_name,
              owner: {name: user.name, display_name: profile.display_name || user.name, avatar_url:},
              updated_at: updated_at&.iso8601,
              generations: generations.map {|g|
                {
                  ulid: g.ulid,
                  tick: g.tick,
                  metadata_url: "#{settings.cloudfront_base_url}/#{g.metadata_s3_key}"
                }
              }
            })
          in Failure(Symbol => status)
            halt status
          end
        end
      end
    end
  end
end
