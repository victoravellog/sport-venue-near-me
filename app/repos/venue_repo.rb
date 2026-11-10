# frozen_string_literal: true

module SportVenueNearMe
  module Repos
    class VenueRepo < SportVenueNearMe::DB::Repo[:venues]
      def count
        venues.count
      end

      def search_point(lat:, lng:, buffer_meters:)
        {
          venues: rows(venues.nearby_point(lat:, lng:, buffer_meters:)),
          buffer_geometry: venues.point_buffer(lat:, lng:, buffer_meters:)
        }
      end

      def search_polygon(geojson, buffer_meters:)
        {
          venues: rows(venues.near_polygon(geojson, buffer_meters:)),
          buffer_geometry: venues.geojson_buffer(geojson, buffer_meters:)
        }
      end

      def search_line(geojson, buffer_meters:)
        {
          venues: rows(venues.near_line(geojson, buffer_meters:)),
          buffer_geometry: venues.geojson_buffer(geojson, buffer_meters:)
        }
      end

      private

      # The spatial queries project computed columns (latitude/longitude/distance_meters)
      # and omit the raw geometry, so they are a read model rather than the Venue entity.
      def rows(relation)
        relation.with(auto_struct: false).to_a
      end
    end
  end
end
