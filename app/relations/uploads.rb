# frozen_string_literal: true

module PastaAtlas
  module Relations
    class Uploads < PastaAtlas::DB::Relation
      schema :uploads, infer: true do
        associations do
          belongs_to :generation
          has_one :current_upload_status
          has_many :upload_events
          has_many :upload_verification_keys
        end
      end
    end
  end
end
