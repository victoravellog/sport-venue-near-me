# frozen_string_literal: true

require "json"

module SportVenueNearMe
  module Relations
    class Venues < SportVenueNearMe::DB::Relation
      schema :venues, infer: true do
        # rom-sql cannot infer the PostGIS geometry type, so declare it explicitly.
        # The raw geometry is never read back (queries select ST_X/ST_Y/ST_Distance) and
        # it is written via PostGIS function expressions, so a pass-through type fits.
        attribute :location, SportVenueNearMe::Types::Any
      end

      # Venues within `buffer_meters` of a point, nearest first.
      def nearby_point(lat:, lng:, buffer_meters:)
        within(point_target(lat, lng), buffer_meters)
      end

      # Venues within `buffer_meters` of a GeoJSON polygon, nearest first.
      def near_polygon(geojson, buffer_meters:)
        within(geojson_target(geojson), buffer_meters)
      end

      # Venues within `buffer_meters` of a GeoJSON line, nearest first.
      def near_line(geojson, buffer_meters:)
        within(geojson_target(geojson), buffer_meters)
      end

      # GeoJSON outline of the search area (buffer) around a point.
      def point_buffer(lat:, lng:, buffer_meters:)
        buffer_geojson(point_target(lat, lng), buffer_meters)
      end

      # GeoJSON outline of the search area (buffer) around a GeoJSON geometry.
      def geojson_buffer(geojson, buffer_meters:)
        buffer_geojson(geojson_target(geojson), buffer_meters)
      end

      private

      def point_target(lat, lng)
        Sequel.function(:ST_SetSRID, Sequel.function(:ST_MakePoint, lng, lat), 4326)
      end

      def geojson_target(geojson)
        Sequel.function(:ST_SetSRID, Sequel.function(:ST_GeomFromGeoJSON, geojson), 4326)
      end

      def within(target, buffer_meters)
        location = Sequel.cast(:location, :geography)
        target_geog = Sequel.cast(target, :geography)

        new(
          dataset
            .where(Sequel.function(:ST_DWithin, location, target_geog, buffer_meters))
            .select(*projection(location, target_geog))
            .order(Sequel.lit("distance_meters"))
        )
      end

      def projection(location, target_geog)
        [
          :id, :name, :sport_type, :source, :source_id, :fetched_at,
          Sequel.function(:ST_Y, :location).as(:latitude),
          Sequel.function(:ST_X, :location).as(:longitude),
          Sequel.function(:ST_Distance, location, target_geog).as(:distance_meters)
        ]
      end

      def buffer_geojson(target, buffer_meters)
        buffered = Sequel.function(:ST_Buffer, Sequel.cast(target, :geography), buffer_meters)
        raw = dataset.db.get(Sequel.function(:ST_AsGeoJSON, Sequel.cast(buffered, :geometry)))
        JSON.parse(raw)
      end
    end
  end
end
