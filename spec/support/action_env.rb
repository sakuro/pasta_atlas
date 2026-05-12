# frozen_string_literal: true

require "rack/icu4x/locale"

RSpec.shared_context "with action locale env" do
  def locale_env(locale="en")
    {Rack::ICU4X::Locale::ENV_KEY => [ICU4X::Locale.parse(locale)]}
  end
end

RSpec.configure do |config|
  config.include_context "with action locale env", :action_env
end
