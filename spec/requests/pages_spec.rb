# frozen_string_literal: true

RSpec.describe "GET /", openapi: false, type: :request do
  it "renders the venue search map" do
    get "/"

    expect(last_response.status).to eq(200)
    expect(last_response.body).to include('x-data="venueMap"')
    expect(last_response.body).to include('class="map-container"')
    expect(last_response.body).to include('id="buffer-range"')
  end

  it "renders translated UI strings" do
    get "/"

    expect(last_response.body).to include("Use the drawing tools")
    expect(last_response.body).to include("Search buffer")
  end
end
