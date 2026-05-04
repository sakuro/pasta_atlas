# frozen_string_literal: true

require "ulid"

module PastaAtlas
  module Repos
    class MapRepo < PastaAtlas::DB::Repo
      def find_by_id(id) = maps.where(id:).one!
      def find_by_ulid(ulid) = maps.where(ulid:).one

      def list_with_complete_generation(page:, per_page:)
        ordered_ids = uploads
          .where(status: "complete")
          .join(:generations, id: :generation_id)
          .group(Sequel[:generations][:map_id])
          .order(Sequel.desc(Sequel.function(:max, Sequel[:uploads][:completed_at])))
          .offset((page - 1) * per_page)
          .limit(per_page)
          .dataset
          .select_map(Sequel[:generations][:map_id])
        return [] if ordered_ids.empty?

        id_to_map = maps.where(id: ordered_ids).to_a.to_h {|m| [m.id, m] }
        ordered_ids.filter_map {|id| id_to_map[id] }
      end

      def count_with_complete_generation
        uploads
          .where(status: "complete")
          .join(:generations, id: :generation_id)
          .dataset
          .unordered
          .select(Sequel[:generations][:map_id])
          .distinct
          .count
      end

      def list_with_complete_generation_by_user(user_id:, limit:)
        user_map_ids = maps.where(user_id:).dataset.select_map(:id)
        return [] if user_map_ids.empty?

        ordered_ids = uploads
          .where(status: "complete")
          .join(:generations, id: :generation_id)
          .where(Sequel[:generations][:map_id] => user_map_ids)
          .group(Sequel[:generations][:map_id])
          .order(Sequel.desc(Sequel.function(:max, Sequel[:uploads][:completed_at])))
          .limit(limit)
          .dataset
          .select_map(Sequel[:generations][:map_id])
        return [] if ordered_ids.empty?

        id_to_map = maps.where(id: ordered_ids).to_a.to_h {|m| [m.id, m] }
        ordered_ids.filter_map {|id| id_to_map[id] }
      end

      def delete_guest_orphans
        guest_id = users.dataset.where(name: "guest").get(:id)
        return 0 unless guest_id

        maps.dataset
          .where(user_id: guest_id)
          .exclude(id: generations.dataset.unordered.select(:map_id))
          .delete
      end

      def find_or_create_by_user_and_mapshot_id(user_id:, mapshot_map_id:, savename: "", name: nil)
        conflict_opts = if name
          {target: %i[user_id mapshot_map_id], update: {name:}}
        else
          {target: %i[user_id mapshot_map_id]}
        end
        maps.dataset.insert_conflict(**conflict_opts).insert(
          user_id:, mapshot_map_id:, ulid: ULID.generate, savename:, name:
        )
        maps.by_user_and_mapshot_id(user_id, mapshot_map_id).one!
      end
    end
  end
end
