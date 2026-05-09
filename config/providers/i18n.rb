# frozen_string_literal: true

Hanami.app.register_provider(:i18n, namespace: true) do
  prepare do
    require "foxtail-runtime"
    require "icu4x-data-recommended"
    require_relative "../../app/i18n"
  end

  start do
    translations_dir = Hanami.app.root.join("app/assets/translations")

    bundles = PastaAtlas::I18n::SUPPORTED_LOCALES.each_with_object({}) do |locale_str, hash|
      path = translations_dir.join("messages.#{locale_str}.ftl")
      locale = ICU4X::Locale.parse(locale_str)
      bundle = Foxtail::Bundle.new(locale)
      bundle.add_resource(Foxtail::Resource.from_file(path)) if path.exist?
      hash[locale_str] = bundle
    end

    register("bundles", bundles)
  end
end
