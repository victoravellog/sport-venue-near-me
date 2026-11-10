# frozen_string_literal: true

require "json"

module SportVenueNearMe
  module Actions
    module API
      module V1
        # Base action for the versioned JSON API. Renders a consistent error envelope
        # `{ "error": "..." }` and maps unexpected failures to a 500.
        class Base < SportVenueNearMe::Action
          handle_exception StandardError => :handle_standard_error

          private

          def handle_standard_error(_request, response, _exception)
            render_error(response, "Unable to process request", status: 500)
          end

          def render_json(response, payload, status: 200)
            response.status = status
            response.headers["Content-Type"] = "application/json; charset=utf-8"
            response.body = JSON.generate(payload)
          end

          def render_error(response, message, status: 422)
            render_json(response, { error: message }, status: status)
          end
        end
      end
    end
  end
end
