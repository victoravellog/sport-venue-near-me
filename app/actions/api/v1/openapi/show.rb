# frozen_string_literal: true

require "yaml"

module SportVenueNearMe
  module Actions
    module API
      module V1
        module Openapi
          # Serves the generated OpenAPI document (doc/openapi.yaml) as JSON so the
          # docs UI and API clients can consume a single source of truth.
          class Show < SportVenueNearMe::Actions::API::V1::Base
            DOC_PATH = "doc/openapi.yaml"

            def handle(_request, response)
              path = SportVenueNearMe::App.root.join(DOC_PATH)
              return render_error(response, "OpenAPI document not found", status: 404) unless path.exist?

              render_json(response, YAML.safe_load(path.read), status: 200)
            end
          end
        end
      end
    end
  end
end
