# auto_register: false
# frozen_string_literal: true

require "json"

module PastaAtlas
  module Views
    module Helpers
      VITE_MANIFEST_PATH = Pathname.new("public/assets/.vite/manifest.json").freeze
      private_constant :VITE_MANIFEST_PATH

      def app_src
        entry = vite_entry("app")
        return "" unless entry

        "/assets/#{entry["file"]}"
      end

      def app_css_srcs
        entry = vite_entry("app")
        return [] unless entry

        Array(entry["css"]).map {|f| "/assets/#{f}" }
      end

      private def vite_entry(name)
        return unless VITE_MANIFEST_PATH.exist?

        manifest = JSON.parse(VITE_MANIFEST_PATH.read)
        manifest.values.find {|v| v["name"] == name && v["isEntry"] }
      end
    end
  end
end
