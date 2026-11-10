# frozen_string_literal: true

# Deterministic test data helpers (no factories). Insert venues directly through
# the ROM relation, building the PostGIS point from lat/lng.
module VenueHelpers
  def insert_venue(source_id:, lat:, lng:, name: "Test Venue", sport_type: "gym", source: "test",
                   fetched_at: Time.now.utc)
    Hanami.app["relations.venues"].dataset.insert(
      name: name,
      sport_type: sport_type,
      location: Sequel.function(:ST_SetSRID, Sequel.function(:ST_MakePoint, lng, lat), 4326),
      source: source,
      source_id: source_id,
      fetched_at: fetched_at
    )
  end
end

RSpec.configure do |config|
  config.include VenueHelpers
end
