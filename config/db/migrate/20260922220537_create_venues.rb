# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :venues do
      primary_key :id

      column :name, String, size: 255, null: false
      column :sport_type, String, size: 100, null: false
      column :location, "geometry(Point,4326)", null: false
      column :source, String, size: 50, null: false
      column :source_id, String, size: 100, null: false
      column :fetched_at, DateTime, null: false
      column :created_at, DateTime, null: false, default: Sequel::CURRENT_TIMESTAMP
      column :updated_at, DateTime, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :location, name: :index_venues_on_location, type: :gist
      index %i[source source_id], name: :index_venues_on_source_and_source_id, unique: true
      index :sport_type, name: :index_venues_on_sport_type
    end
  end
end
