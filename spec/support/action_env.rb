# frozen_string_literal: true

require "rack/icu4x/locale"

module ActionEnv
  def locale_env(locale="en")
    {Rack::ICU4X::Locale::ENV_KEY => [ICU4X::Locale.parse(locale)]}
  end
end

RSpec.configure do |config|
  config.include ActionEnv
end
