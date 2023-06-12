# frozen_string_literal: true

require "open-weather-ruby-client"
require "geocoder"

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

  let(:daily_forecast) {
    OpenWeather::Models::OneCall::DailyWeather.new(
      dt: 1684951200,
      sunrise: 1684926645,
      sunset: 1684977332,
      moonrise: 1684941060,
      moonset: 1684905480,
      moon_phase: 0.16,
      summary: "Expect a day of partly cloudy with rain",
      temp: {
        day: 299.03,
        min: 290.69,
        max: 300.35,
        night: 291.45,
        eve: 297.51,
        morn: 292.55
      },
      feels_like: {
        day: 299.21,
        night: 291.37,
        eve: 297.86,
        morn: 292.87
      },
      pressure: 1016,
      humidity: 59,
      dew_point: 290.48,
      wind_speed: 3.98,
      wind_deg: 76,
      wind_gust: 8.92,
      weather: [
        {
          id: 500,
          main: "Rain",
          description: "light rain",
          icon: "10d"
        }
      ],
      clouds: 92,
      pop: 0.47,
      rain: 0.15,
      uvi: 9.23
    )
  }
  let(:one_call_response) {
    OpenWeather::Models::OneCall::Weather.new(
      lat: 33.44,
      lon: -94.04,
      timezone: "America/Chicago",
      timezone_offset: -18000,
      daily: [daily_forecast]
    )
  }

  before do
    allow(subject.client).to receive(:current_weather)
      .with(city: "Boston", units: nil)
      .and_return(response)

    allow(subject.client).to receive(:one_call)
      .with(lat: 41.8755616, lon: 87.6244212, units: nil, exclude: ["minutely", "hourly"])
      .and_return(one_call_response)

    allow(Geocoder).to receive(:search)
      .with("Boston")
      .and_return([42.3602534, -71.0582912])

    allow(Geocoder).to receive(:search)
      .with("Chicago")
      .and_return([41.8755616, 87.6244212])
  end

  describe "#execute" do
    it "returns current weather" do
      expect(subject.execute(input: "Boston, current")).to include("282.57")
    end
    # TODO: Fix by mocking gecoding response above
    xit "returns forecast weather" do
      subject.add_geocoding(api_key: "123")
      expect(subject.execute(input: "Chicago, forecast")).to include("299.03")
    end
  end
end
