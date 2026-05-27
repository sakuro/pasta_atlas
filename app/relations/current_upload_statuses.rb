# frozen_string_literal: true

module PastaAtlas
  module Relations
    class CurrentUploadStatuses < PastaAtlas::DB::Relation
      schema :current_upload_statuses, infer: true
    end
  end
end
