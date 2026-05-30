# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Maps
      class Index < PastaAtlas::Action
        include Deps[list_maps: "operations.maps.list"]

        def handle(request, response)
          page = [Integer(request.params[:page] || 1, exception: false) || 1, 1].max
          case list_maps.call(page:)
          in Success(payload)
            if request.env["HTTP_ACCEPT"]&.include?("application/json")
              json_response(response, serialize(payload))
            else
              response.render(view)
            end
          end
        end

        private def serialize(payload)
          {
            maps: payload[:map_infos].map {|m|
              {
                ulid: m.ulid,
                display_name: m.display_name,
                user_name: m.user_info.name,
                author_display_name: m.user_info.display_name,
                author_avatar_url: m.user_info.avatar_url,
                thumbnail_url: m.thumbnail_url,
                metadata_url: m.metadata_url,
                updated_at: m.updated_at&.iso8601
              }
            },
            page: payload[:page],
            per_page: payload[:per_page],
            total: payload[:total]
          }
        end
      end
    end
  end
end
