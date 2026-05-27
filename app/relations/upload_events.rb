# frozen_string_literal: true

module PastaAtlas
  module Relations
    class UploadEvents < PastaAtlas::DB::Relation
      schema :upload_events, infer: true do
        associations do
          belongs_to :upload
        end
      end
    end
  end
end
