# frozen_string_literal: true

module PastaAtlas
  module Actions
    module API
      module Uploads
        class Create < PastaAtlas::Action
          include Deps[create_upload: "operations.uploads.create"]

          contract do
            params do
              required(:metadata).filled(:hash)
              required(:total_image_count).filled(:integer)
              required(:name).filled(:string)
            end

            rule(:metadata) do
              meta = values[:metadata]
              # gen_map_id / gen_unique_id produce 8 hex chars sliced from SHA-256:
              # https://github.com/Palats/mapshot/blob/ddad172f187d08e56df720efe2fe0bddfb65e347/mod/control.lua#L206-L222
              mapshot_id_pattern = /\A[0-9a-f]{8}\z/
              # game.tick is an unsigned 32-bit counter:
              # https://lua-api.factorio.com/latest/classes/LuaGameScript.html#tick
              tick_max = 4_294_967_295

              key(%i[metadata map_id]).failure("is invalid") unless meta[:map_id].is_a?(String) && mapshot_id_pattern.match?(meta[:map_id])
              key(%i[metadata unique_id]).failure("is invalid") unless meta[:unique_id].is_a?(String) && mapshot_id_pattern.match?(meta[:unique_id])
              tick_int = Integer(meta[:tick], exception: false)
              key(%i[metadata tick]).failure("is invalid") unless tick_int&.between?(0, tick_max)
            end
          end

          def handle(request, response)
            halt :bad_request unless request.params.valid?
            halt :forbidden if current_user_id(request) == guest_user_id

            result = create_upload.call(
              user_id: current_user_id(request),
              metadata: request.params[:metadata].to_h,
              total_image_count: request.params[:total_image_count],
              name: request.params[:name]
            )

            case result
            in Success({upload:, generation:, map:})
              json_response(
                response,
                {
                  ulid: upload.ulid,
                  map_ulid: map.ulid,
                  generation_ulid: generation.ulid
                },
                status: :created
              )
            in Failure(:invalid, error)
              json_response(response, {error:}, status: 422)
            in Failure(:s3_error)
              halt :bad_gateway
            in Failure(Symbol => status)
              halt status
            end
          end
        end
      end
    end
  end
end
