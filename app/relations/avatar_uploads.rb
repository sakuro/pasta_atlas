# frozen_string_literal: true

module PastaAtlas
  module Relations
    class AvatarUploads < PastaAtlas::DB::Relation
      schema :avatar_uploads, infer: true do
        associations do
          belongs_to :user
        end
      end
    end
  end
end
