# frozen_string_literal: true

require "open-weather-ruby-client"

RSpec.describe Langchain::Tool::Weather do
  subject {
    described_class.new(api_key: "123")
  }

  let(:response) {
    OpenWeather::Models::City::Weather.new(
      name: "Boston",
      dt: Time.now,
      main: {
        feels_like: 277.73,
        humidity: 81,
        pressure: 1005,
        temp: 282.57,
        temp_max: 283.15,
        temp_min: 281.48
      }
    )
  }

  before do
    allow(subject.client).to receive(:current_weather)
      .with(city: "Boston")
      .and_return(response)
  end

  describe "#execute" do
    it "returns current weather" do
      expect(subject.execute(input: "Boston, current")).to include("282.57 degrees Farenheit")
    end
    it "returns forecast weather" do
      expect(subject.execute(input: "Boston, forecast")).to include("forecast not yet implemented")
    end
  end
end
