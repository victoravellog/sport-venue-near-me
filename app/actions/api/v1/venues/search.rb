# frozen_string_literal: true

module SportVenueNearMe
  module Actions
    module API
      module V1
        module Venues
          class Search < SportVenueNearMe::Actions::API::V1::Base
            include Deps[operation: "operations.venues.search"]

            def handle(request, response)
              result = operation.call(symbolized(request.params))

              if result.success?
                render_json(response, result.value!, status: 200)
              else
                status, message = result.failure
                render_error(response, message, status: http_status(status))
              end
            end

            private

            def symbolized(params)
              params.to_h.transform_keys(&:to_sym)
            end

            def http_status(status)
              { bad_request: 400, unprocessable_entity: 422 }.fetch(status, 500)
            end
          end
        end
      end
    end
  end
end
