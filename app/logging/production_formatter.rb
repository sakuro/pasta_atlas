# frozen_string_literal: true

# auto_register: false

require "dry/logger"

module PastaAtlas
  module Logging
    # JSON log formatter for production.
    #
    # Hanami puts the request parameters in every request log entry. For uploads these are the
    # whole mapshot.json and up to 200 file names, which makes the logs large and keeps user
    # content in CloudWatch. The path, status and the ULIDs in the path are enough to follow a
    # request, so `params` is dropped.
    class ProductionFormatter < Dry::Logger::Formatters::JSON
      def format_values(entry)
        super.except(:params)
      end
    end
  end
end
