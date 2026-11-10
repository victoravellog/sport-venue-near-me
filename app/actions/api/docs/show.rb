# frozen_string_literal: true

module SportVenueNearMe
  module Actions
    module API
      module Docs
        # Renders the Scalar API reference UI, pointing at the JSON OpenAPI document.
        # Served without the app layout (no Leaflet/Alpine) and with a docs-scoped CSP:
        # Scalar loads from jsDelivr and injects inline scripts/styles, which the app's
        # strict same-origin policy would otherwise block.
        class Show < SportVenueNearMe::Action
          SPEC_URL = "/api/v1/openapi.json"

          CSP = [
            "default-src 'self'",
            "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net",
            "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net https://fonts.googleapis.com",
            "font-src 'self' https://fonts.gstatic.com data:",
            "img-src 'self' data: https:",
            "connect-src 'self'"
          ].join("; ")

          HTML = <<~HTML.freeze
            <!doctype html>
            <html>
              <head>
                <title>Sport Venue Near Me API</title>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
              </head>
              <body>
                <script id="api-reference" data-url="#{SPEC_URL}"></script>
                <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
              </body>
            </html>
          HTML

          def handle(_request, response)
            response.headers["Content-Type"] = "text/html; charset=utf-8"
            response.headers["Content-Security-Policy"] = CSP
            response.body = HTML
          end
        end
      end
    end
  end
end
