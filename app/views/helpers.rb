# auto_register: false
# frozen_string_literal: true

require "json"

module PastaAtlas
  module Views
    module Helpers
      VITE_MANIFEST_PATH = Pathname.new("public/assets/islands/.vite/manifest.json").freeze
      private_constant :VITE_MANIFEST_PATH

      # Returns the URL of a Vite-built island script by logical name.
      # Looks up the hashed filename from the Vite manifest to ensure cache busting.
      #
      # @param name [String] the island name as defined in vite.config.ts input keys
      # @return [String] the URL path to the island script, or empty string if not found
      def island_src(name)
        entry = vite_island_entry(name)
        return "" unless entry

        "/assets/islands/#{entry["file"]}"
      end

      # Returns CSS URLs extracted alongside a Vite-built island.
      #
      # @param name [String] the island name as defined in vite.config.ts input keys
      # @return [Array<String>] URL paths to associated CSS files
      def island_css_srcs(name)
        entry = vite_island_entry(name)
        return [] unless entry

        Array(entry["css"]).map {|f| "/assets/islands/#{f}" }
      end

      private def vite_island_entry(name)
        return unless VITE_MANIFEST_PATH.exist?

        manifest = JSON.parse(VITE_MANIFEST_PATH.read)
        manifest.values.find {|v| v["name"] == name && v["isEntry"] }
      end
    end
  end
end
