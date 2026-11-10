# frozen_string_literal: true

require "json"
require "time"

RSpec.describe "GET /api/v1/venues/search", :db, type: :request do
  let(:body) { JSON.parse(last_response.body) }

  before do
    insert_venue(source_id: "center", lat: 53.9600, lng: -1.0800, name: "Center")
    insert_venue(source_id: "near",   lat: 53.9600, lng: -1.0790, name: "Near")
    insert_venue(source_id: "far",    lat: 53.9600, lng: -0.9800, name: "Far")
  end

  describe "point search" do
    it "returns venues within the buffer with the expected envelope" do
      get "/api/v1/venues/search?lat=53.96&lng=-1.08&buffer=2000"

      expect(last_response.status).to eq(200)
      expect(last_response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
      expect(body["data"].map { |v| v["name"] }).to contain_exactly("Center", "Near")

      venue = body["data"].first
      expect(venue.keys).to include("id", "name", "sport_type", "latitude", "longitude", "distance_meters", "source",
                                    "fetched_at")

      expect(body["meta"]).to include(
        "search_type" => "point",
        "total_results" => 2,
        "buffer_meters" => 2000
      )
      expect(body["meta"]["buffer_geometry"]["type"]).to eq("Polygon")
    end

    it "defaults the buffer to 500 meters" do
      get "/api/v1/venues/search?lat=53.96&lng=-1.08"
      expect(body["meta"]["buffer_meters"]).to eq(500)
    end

    it "orders results by ascending distance" do
      get "/api/v1/venues/search?lat=53.96&lng=-1.08&buffer=2000"
      distances = body["data"].map { |v| v["distance_meters"] }
      expect(distances).to eq(distances.sort)
    end
  end

  describe "polygon and line searches" do
    it "reports the polygon search type" do
      polygon = '{"type":"Polygon","coordinates":[[[-1.0810,53.9590],[-1.0785,53.9590],[-1.0785,53.9610],[-1.0810,53.9610],[-1.0810,53.9590]]]}'
      get "/api/v1/venues/search", polygon: polygon, buffer: 100
      expect(last_response.status).to eq(200)
      expect(body["meta"]["search_type"]).to eq("polygon")
    end

    it "reports the line search type" do
      line = '{"type":"LineString","coordinates":[[-1.0800,53.9600],[-1.0700,53.9600]]}'
      get "/api/v1/venues/search", line: line, buffer: 200
      expect(last_response.status).to eq(200)
      expect(body["meta"]["search_type"]).to eq("line")
    end
  end

  describe "provenance and freshness" do
    let(:fetched_at) { Time.utc(2026, 9, 1, 12, 0, 0) }

    before do
      insert_venue(source_id: "osm-1", lat: 53.9600, lng: -1.0801, name: "Sourced",
                   source: "openstreetmap", fetched_at: fetched_at)
    end

    it "exposes source and fetched_at for every venue in data" do
      get "/api/v1/venues/search?lat=53.96&lng=-1.08&buffer=2000"

      expect(body["data"]).to all(include("source", "fetched_at"))
      sourced = body["data"].find { |v| v["name"] == "Sourced" }
      expect(sourced["source"]).to eq("openstreetmap")
      expect(Time.parse(sourced["fetched_at"])).to eq(fetched_at)
    end
  end

  describe "validation errors" do
    it "returns 400 when no search parameters are given" do
      get "/api/v1/venues/search"
      expect(last_response.status).to eq(400)
      expect(body["error"]).to eq("Missing search parameters. Provide lat/lng, polygon, or line.")
    end

    it "rejects out-of-range latitude" do
      get "/api/v1/venues/search?lat=200&lng=0"
      expect(last_response.status).to eq(422)
      expect(body["error"]).to eq("lat must be between -90 and 90")
    end

    it "rejects out-of-range longitude" do
      get "/api/v1/venues/search?lat=0&lng=999"
      expect(last_response.status).to eq(422)
      expect(body["error"]).to eq("lng must be between -180 and 180")
    end

    it "rejects an out-of-range buffer" do
      get "/api/v1/venues/search?lat=0&lng=0&buffer=50"
      expect(last_response.status).to eq(422)
      expect(body["error"]).to eq("buffer must be between 100 and 10000 meters")
    end

    it "rejects invalid polygon GeoJSON" do
      get "/api/v1/venues/search", polygon: "not-json"
      expect(last_response.status).to eq(422)
      expect(body["error"]).to eq("Invalid polygon: must be a valid GeoJSON Polygon")
    end

    it "rejects invalid line GeoJSON" do
      get "/api/v1/venues/search", line: '{"type":"Polygon"}'
      expect(last_response.status).to eq(422)
      expect(body["error"]).to eq("Invalid line: must be a valid GeoJSON LineString")
    end
  end
end
