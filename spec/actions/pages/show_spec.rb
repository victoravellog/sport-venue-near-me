# frozen_string_literal: true

RSpec.describe SportVenueNearMe::Actions::Pages::Show do
  subject(:action) { described_class.new }

  it "responds successfully" do
    expect(action.call({})).to be_successful
  end
end
