# frozen_string_literal: true

module PastaAtlas
  module Relations
    class UploadVerificationKeys < PastaAtlas::DB::Relation
      schema :upload_verification_keys, infer: true do
        associations do
          belongs_to :upload
        end
      end
    end
  end
end
