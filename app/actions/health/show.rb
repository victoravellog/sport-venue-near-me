# frozen_string_literal: true

require "json"

module SportVenueNearMe
  module Actions
    module Health
      # Liveness probe for load balancers and uptime checks. Returns 200 while the
      # app can serve requests; the framework surfaces boot failures as a non-200.
      class Show < SportVenueNearMe::Action
        def handle(_request, response)
          response.status = 200
          response.headers["Content-Type"] = "application/json; charset=utf-8"
          response.body = JSON.generate(status: "ok")
        end
      end
    end
  end
end
