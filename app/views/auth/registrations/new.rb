# frozen_string_literal: true

module PastaAtlas
  module Views
    module Auth
      module Registrations
        class New < Hanami::View
          expose :suggested_name, :error
        end
      end
    end
  end
end
