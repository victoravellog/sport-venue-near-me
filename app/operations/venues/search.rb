# frozen_string_literal: true

module SportVenueNearMe
  module Operations
    module Venues
      # Detects the search type, validates the params and returns the JSON payload
      # (data + meta) for the venue search endpoint. Buffer defaults to 500 m.
      class Search < SportVenueNearMe::Operation
        include Deps[
          repo: "repos.venue_repo",
          contract: "contracts.api.v1.venue_search_contract"
        ]

        DEFAULT_BUFFER = 500

        def call(params)
          search_type = step detect_type(params)
          buffer = buffer_for(params)
          step validate(params, buffer)
          result = fetch(search_type, params, buffer)

          payload(search_type, result, buffer)
        end

        private

        def detect_type(params)
          if present?(params[:lat]) && present?(params[:lng])
            Success(:point)
          elsif present?(params[:polygon])
            Success(:polygon)
          elsif present?(params[:line])
            Success(:line)
          else
            Failure([:bad_request, "Missing search parameters. Provide lat/lng, polygon, or line."])
          end
        end

        def buffer_for(params)
          raw = params[:buffer]
          present?(raw) ? Integer(raw, exception: false) : DEFAULT_BUFFER
        end

        def validate(params, buffer)
          result = contract.call(params.merge(buffer: buffer))
          return Success() if result.success?

          Failure([:unprocessable_entity, result.errors.first.text])
        end

        def fetch(search_type, params, buffer)
          case search_type
          when :point
            repo.search_point(lat: params[:lat].to_f, lng: params[:lng].to_f, buffer_meters: buffer)
          when :polygon
            repo.search_polygon(params[:polygon], buffer_meters: buffer)
          when :line
            repo.search_line(params[:line], buffer_meters: buffer)
          end
        end

        def payload(search_type, result, buffer)
          {
            data: result[:venues].map { |venue| venue_json(venue) },
            meta: {
              search_type: search_type.to_s,
              total_results: result[:venues].size,
              buffer_meters: buffer,
              buffer_geometry: result[:buffer_geometry]
            }
          }
        end

        def venue_json(venue)
          {
            id: venue[:id],
            name: venue[:name],
            sport_type: venue[:sport_type],
            latitude: venue[:latitude],
            longitude: venue[:longitude],
            distance_meters: venue[:distance_meters]&.round(1),
            source: venue[:source],
            fetched_at: venue[:fetched_at]&.iso8601
          }
        end

        def present?(value)
          !value.nil? && value != ""
        end
      end
    end
  end
end
