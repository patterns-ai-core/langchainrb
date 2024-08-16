# spec/langchain/tool/weather_spec.rb

require "spec_helper"
require "langchain/tool/weather"

RSpec.describe Langchain::Tool::Weather do
  let(:api_key) { "dummy_api_key" }
  let(:weather_tool) { described_class.new(api_key: api_key) }

  describe "#initialize" do
    it "sets the API key" do
      expect(weather_tool.instance_variable_get(:@api_key)).to eq(api_key)
    end
  end

  describe "#get_current_weather" do
    let(:city) { "New York" }
    let(:state_code) { "NY" }
    let(:country_code) { "US" }
    let(:units) { "imperial" }

    context "when the API request is successful" do
      before do
        allow(weather_tool).to receive(:send_request).and_return(
          [{"lat" => 40.7128, "lon" => -74.0060}],
          {
            "main" => {"temp" => 72, "humidity" => 50},
            "weather" => [{"description" => "clear sky"}],
            "wind" => {"speed" => 5}
          }
        )
      end

      it "returns the parsed weather data" do
        result = weather_tool.get_current_weather(city: city, state_code: state_code, country_code: country_code)
        expect(result).to eq({
          temperature: "72 °F",
          humidity: "50%",
          description: "clear sky",
          wind_speed: "5 mph"
        })
      end

      it "uses the correct units" do
        weather_tool.get_current_weather(city: city, state_code: state_code, units: "metric")
        expect(weather_tool).to have_received(:send_request).with(
          hash_including(params: hash_including(units: "metric"))
        )
      end
    end

    context "when the location is not found" do
      before do
        allow(weather_tool).to receive(:send_request).and_return([])
      end

      it "returns an error message" do
        result = weather_tool.get_current_weather(city: city, state_code: state_code)
        expect(result).to eq("Location not found")
      end
    end

    context "when the API request fails" do
      before do
        allow(weather_tool).to receive(:send_request).and_return("API request failed: 404 - Not Found")
      end

      it "returns the error message" do
        result = weather_tool.get_current_weather(city: city, state_code: state_code)
        expect(result).to eq("API request failed: 404 - Not Found")
      end
    end
  end

  describe "input validation" do
    it "raises an error for empty city" do
      expect {
        weather_tool.get_current_weather(city: "", state_code: "NY")
      }.to raise_error(ArgumentError, "City name cannot be empty")
    end

    it "raises an error for empty state_code" do
      expect {
        weather_tool.get_current_weather(city: "New York", state_code: "")
      }.to raise_error(ArgumentError, "State code cannot be empty")
    end

    it "raises an error for invalid units" do
      expect {
        weather_tool.get_current_weather(city: "New York", state_code: "NY", units: "invalid")
      }.to raise_error(ArgumentError, 'Invalid units. Use "imperial", "standard" or "metric"')
    end
  end
end
