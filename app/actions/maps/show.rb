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
          in Success({map:, user:, generations:})
            json_response(response, {
              ulid: map.ulid,
              display_name: map.display_name,
              owner: {name: user.name},
              generations: generations.map {|g|
                {
                  ulid: g.ulid,
                  tick: g.tick,
                  metadata_url: "#{settings.cloudfront_base_url}/#{g.metadata_s3_key}"
                }
              }
            })
          in Failure(:not_found)
            response.status = 404
          end
        end
      end
    end
  end
end
