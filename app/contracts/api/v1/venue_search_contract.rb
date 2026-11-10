# frozen_string_literal: true

require "dry/validation"
require "json"

module SportVenueNearMe
  module Contracts
    module API
      module V1
        # Validates the venue search params, reproducing the exact /api/v1 error
        # messages. Coordinate ranges, buffer bounds and GeoJSON shape are checked
        # here; search-type detection lives in the operation.
        class VenueSearchContract < Dry::Validation::Contract
          MIN_BUFFER = 100
          MAX_BUFFER = 10_000

          params do
            optional(:lat).maybe(:string)
            optional(:lng).maybe(:string)
            optional(:buffer).maybe(:integer)
            optional(:polygon).maybe(:string)
            optional(:line).maybe(:string)
          end

          rule(:buffer) do
            value = values[:buffer]
            unless value.is_a?(Integer) && value.between?(MIN_BUFFER, MAX_BUFFER)
              key.failure("buffer must be between #{MIN_BUFFER} and #{MAX_BUFFER} meters")
            end
          end

          rule(:lat) do
            if key?
              coord = Float(value, exception: false)
              key.failure("lat must be between -90 and 90") unless coord&.between?(-90, 90)
            end
          end

          rule(:lng) do
            if key?
              coord = Float(value, exception: false)
              key.failure("lng must be between -180 and 180") unless coord&.between?(-180, 180)
            end
          end

          rule(:polygon) do
            key.failure("Invalid polygon: must be a valid GeoJSON Polygon") if key? && !valid_geojson?(value, "Polygon")
          end

          rule(:line) do
            key.failure("Invalid line: must be a valid GeoJSON LineString") if key? && !valid_geojson?(value,
                                                                                                       "LineString")
          end

          private

          def valid_geojson?(raw, type)
            parsed = JSON.parse(raw)
            parsed["type"] == type && parsed["coordinates"].is_a?(Array)
          rescue JSON::ParserError, TypeError
            false
          end
        end
      end
    end
  end
end
