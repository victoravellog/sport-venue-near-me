# frozen_string_literal: true

# The OpenAPI document is generated from the request specs on demand:
#   OPENAPI=1 bundle exec rspec spec/requests/api
# It is loaded only in that mode so ordinary test runs stay fast and untouched.
# rspec-openapi merges into doc/openapi.yaml, preserving hand-written descriptions.
if ENV["OPENAPI"]
  require "rspec/openapi"

  RSpec::OpenAPI.path = "doc/openapi.yaml"
  RSpec::OpenAPI.title = "Sport Venue Near Me API"
  RSpec::OpenAPI.application_version = "1.0.0"
  RSpec::OpenAPI.info = {
    description: "Versioned JSON API to find sports venues near a point, polygon, or line."
  }
  RSpec::OpenAPI.servers = [{ url: "http://localhost:2300" }]
end
