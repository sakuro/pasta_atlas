# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Users
        module Maps
          class Show < PastaAtlas::Action
            include Deps[
              "operations.user.find_by_name",
              "settings",
              show_map: "operations.maps.show"
            ]

            def handle(request, response)
              result = find_by_name.call(user_name: request.params[:user_name])
              case result
              in Failure(Symbol => status)
                halt status
              in Success(user)
                map_result = show_map.call(ulid: request.params[:ulid])
                case map_result
                in Failure(Symbol => status)
                  halt status
                in Success({map:, user: map_user, profile:, updated_at:, generations:})
                  halt :not_found if map.user_id != user.id

                  avatar_url = profile.avatar_s3_key ? "#{settings.cloudfront_base_url}/#{profile.avatar_s3_key}" : nil
                  json_response(response, {
                    ulid: map.ulid,
                    display_name: map.display_name,
                    owner: {name: map_user.name, display_name: profile.display_name || map_user.name, avatar_url:},
                    updated_at: updated_at&.iso8601,
                    generations: generations.map {|g|
                      {
                        ulid: g.ulid,
                        tick: g.tick,
                        metadata_url: "#{settings.cloudfront_base_url}/#{g.metadata_s3_key}"
                      }
                    }
                  })
                end
              end
            end
          end
        end
      end
    end
  end
end
