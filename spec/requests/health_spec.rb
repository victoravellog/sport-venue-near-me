# frozen_string_literal: true

require "json"

RSpec.describe "GET /up", openapi: false, type: :request do
  it "reports the app is healthy" do
    get "/up"

    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
    expect(JSON.parse(last_response.body)).to eq("status" => "ok")
  end
end
