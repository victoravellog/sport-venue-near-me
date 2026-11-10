# frozen_string_literal: true

Hanami.app.register_provider(:i18n) do
  prepare do
    require "i18n"
  end

  start do
    I18n.load_path += Dir[target.root.join("config", "i18n", "*.yml").to_s]
    I18n.available_locales = %i[en]
    I18n.default_locale = :en
    I18n.backend.load_translations

    register "i18n", I18n
  end
end
