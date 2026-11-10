# frozen_string_literal: true

require "hanami"

module SportVenueNearMe
  class App < Hanami::App
    # Allow Leaflet from the unpkg CDN and Google Fonts. Alpine runs from the CSP-friendly
    # build (bundled, same-origin), so no 'unsafe-eval' is needed. img_src/style_src already
    # permit https (OSM tiles, Leaflet CSS) by default.
    config.actions.content_security_policy[:script_src] += " https://unpkg.com"
    config.actions.content_security_policy[:font_src] += " https://fonts.gstatic.com"
  end
end
