# frozen_string_literal: true

RSpec.describe SportVenueNearMe::Repos::VenueRepo, :db do
  subject(:repo) { Hanami.app["repos.venue_repo"] }

  # York-area coordinates. At this latitude ~0.001 deg of longitude is ~65 m,
  # 0.01 deg ~655 m and 0.1 deg ~6.5 km. Realistic coords avoid the geography
  # singularities that arise exactly on the equator/prime meridian.
  before do
    insert_venue(source_id: "center", lat: 53.9600, lng: -1.0800, name: "Center")
    insert_venue(source_id: "near",   lat: 53.9600, lng: -1.0790, name: "Near")
    insert_venue(source_id: "mid",    lat: 53.9600, lng: -1.0700, name: "Mid")
    insert_venue(source_id: "far",    lat: 53.9600, lng: -0.9800, name: "Far")
  end

  describe "#search_point" do
    subject(:result) { repo.search_point(lat: 53.9600, lng: -1.0800, buffer_meters: 2000) }

    it "returns only venues within the buffer" do
      expect(result[:venues].map { |v| v[:name] }).to contain_exactly("Center", "Near", "Mid")
    end

    it "orders venues by ascending distance" do
      distances = result[:venues].map { |v| v[:distance_meters] }
      expect(distances).to eq(distances.sort)
      expect(result[:venues].first[:name]).to eq("Center")
    end

    it "computes distance in meters via PostGIS" do
      near = result[:venues].find { |v| v[:name] == "Near" }
      expect(near[:distance_meters]).to be_within(15).of(65)
    end

    it "returns a GeoJSON buffer outline" do
      expect(result[:buffer_geometry]["type"]).to eq("Polygon")
    end

    it "exposes provenance and freshness" do
      center = result[:venues].first
      expect(center[:source]).to eq("test")
      expect(center[:fetched_at]).to be_a(Time)
    end
  end

  describe "#search_polygon" do
    it "returns venues within the buffered polygon, ordered by distance" do
      polygon = '{"type":"Polygon","coordinates":[[[-1.0810,53.9590],[-1.0785,53.9590],[-1.0785,53.9610],[-1.0810,53.9610],[-1.0810,53.9590]]]}'
      names = repo.search_polygon(polygon, buffer_meters: 100)[:venues].map { |v| v[:name] }
      expect(names).to include("Center", "Near")
      expect(names).not_to include("Far")
    end
  end

  describe "#search_line" do
    it "returns venues within the buffered line, ordered by distance" do
      line = '{"type":"LineString","coordinates":[[-1.0800,53.9600],[-1.0700,53.9600]]}'
      result = repo.search_line(line, buffer_meters: 200)
      distances = result[:venues].map { |v| v[:distance_meters] }
      expect(distances).to eq(distances.sort)
      expect(result[:venues].map { |v| v[:name] }).to include("Center", "Near", "Mid")
    end
  end
end
