# frozen_string_literal: true

module SportVenueNearMe
  class Routes < Hanami::Routes
    root to: "pages.show"

    get "up", to: "health.show"

    scope "api" do
      get "docs", to: "api.docs.show"
    end

    scope "api/v1" do
      get "venues/search", to: "api.v1.venues.search"
      get "openapi.json", to: "api.v1.openapi.show"
    end
  end
end
