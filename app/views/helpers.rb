# auto_register: false
# frozen_string_literal: true

module SportVenueNearMe
  module Views
    module Helpers
      # Translate a key using the app's i18n provider, so templates can call `t("map.searching")`.
      def t(key, **)
        Hanami.app["i18n"].t(key, **)
      end
    end
  end
end
