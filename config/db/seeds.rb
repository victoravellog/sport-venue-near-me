# frozen_string_literal: true

# Seed sports venues around York, UK for development/demo purposes.
# Idempotent: upsert by (source, source_id) so re-running never duplicates rows.
# Run with `hanami db seed` (also run as part of `hanami db prepare`).

venues = Hanami.app["relations.venues"]

YORK_VENUES = [
  { name: "York Sports Village", sport_type: "multi-sport", lat: 53.9576, lng: -1.0348 },
  { name: "Bootham Park Tennis Courts", sport_type: "tennis", lat: 53.9680, lng: -1.0890 },
  { name: "York City Football Club", sport_type: "football", lat: 53.9697, lng: -1.0922 },
  { name: "York Railway Institute Swimming Pool", sport_type: "swimming", lat: 53.9571, lng: -1.0937 },
  { name: "Clifton Park Rugby Club", sport_type: "rugby", lat: 53.9752, lng: -1.0834 },
  { name: "York Cricket Club", sport_type: "cricket", lat: 53.9654, lng: -1.0741 },
  { name: "The Gym York", sport_type: "gym", lat: 53.9580, lng: -1.0802 },
  { name: "York Athletics Club", sport_type: "athletics", lat: 53.9512, lng: -1.0658 },
  { name: "Energise Leisure Centre", sport_type: "multi-sport", lat: 53.9434, lng: -1.0512 },
  { name: "David Lloyd York", sport_type: "multi-sport", lat: 53.9312, lng: -1.0423 },
  { name: "Heworth Tennis Club", sport_type: "tennis", lat: 53.9621, lng: -1.0512 },
  { name: "Tang Hall Community Centre Gym", sport_type: "gym", lat: 53.9678, lng: -1.0421 },
  { name: "Rowntree Park Football Pitches", sport_type: "football", lat: 53.9423, lng: -1.0834 },
  { name: "University of York Sports Centre", sport_type: "multi-sport", lat: 53.9471, lng: -1.0534 },
  { name: "York St John University Sports", sport_type: "multi-sport", lat: 53.9654, lng: -1.0712 },
  { name: "Dringhouses Pool", sport_type: "swimming", lat: 53.9312, lng: -1.1123 },
  { name: "Copmanthorpe Tennis Club", sport_type: "tennis", lat: 53.9156, lng: -1.1234 },
  { name: "Bishopthorpe Cricket Club", sport_type: "cricket", lat: 53.9123, lng: -1.0834 },
  { name: "Acomb Rugby Club", sport_type: "rugby", lat: 53.9534, lng: -1.1234 },
  { name: "PureGym York Clifton Moor", sport_type: "gym", lat: 53.9912, lng: -1.0912 }
].freeze

now = Time.now.utc

YORK_VENUES.each_with_index do |venue, index|
  point = Sequel.function(:ST_SetSRID, Sequel.function(:ST_MakePoint, venue[:lng], venue[:lat]), 4326)

  venues.dataset
        .insert_conflict(
          target: %i[source source_id],
          update: {
            name: venue[:name],
            sport_type: venue[:sport_type],
            location: point,
            fetched_at: now,
            updated_at: now
          }
        )
        .insert(
          name: venue[:name],
          sport_type: venue[:sport_type],
          location: point,
          source: "seed",
          source_id: "york-#{index + 1}",
          fetched_at: now
        )
end

puts "Seeded #{YORK_VENUES.size} venues (source=seed). Total venues: #{venues.dataset.count}"
