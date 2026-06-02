# auto_register: false
# frozen_string_literal: true

require "json"

module PastaAtlas
  module I18n
    SUPPORTED_LOCALES = JSON.parse(Pathname.new(__dir__).join("../config/supported_locales.json").read).freeze
    public_constant :SUPPORTED_LOCALES
  end
end
