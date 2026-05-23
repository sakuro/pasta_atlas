# auto_register: false
# frozen_string_literal: true

module PastaAtlas
  module Actions
    module Pages
      class Base < PastaAtlas::Action
        def handle(request, response)
          response.render(view, locale_tags: locale_tags(request))
        end

        private def locale_tags(request)
          (request.env[::Rack::ICU4X::Locale::ENV_KEY] || []).map(&:to_s)
        end
      end
    end
  end
end
