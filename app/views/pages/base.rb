# auto_register: false
# frozen_string_literal: true

module PastaAtlas
  module Views
    module Pages
      class Base < Hanami::View
        expose(:locale_partial) do |locale_tags:|
          template = self.class.config.template
          template_base = File.basename(template)
          found = locale_tags.find {|tag|
            self.class.config.paths.any? {|path| path.lookup(template, "_#{tag}", "html") }
          }
          "#{template_base}/#{found || "en"}"
        end
      end
    end
  end
end
