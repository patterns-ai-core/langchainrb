# frozen_string_literal: true

module Langchain::Tool
  class Weather < Base
    #
    # A weather tool that gets current or forecast weather data
    #
    # 1. Current weather data is free for 1000 calls per day (https://home.openweathermap.org/api_keys)
    #
    # 2. Forecast weather data is free for 1000 calls per day, but requires CC info to sign up for the
    #    Open Weather "One Call API" (https://openweathermap.org/api/one-call-api).
    #
    # 3. Professional OpenWeather services for historical data are not supported by this tool yet.
    #
    # Gem requirements:
    #   gem "open-weather-ruby-client", "~> 0.3.0"
    #   api_key: https://home.openweathermap.org/api_keys
    #
    # Usage:
    # weather = Langchain::Tool::Weather.new(api_key: "YOUR_API_KEY")
    # weather.execute(input: "Boston, current, imperial")
    #

    NAME = "weather"

    description <<~DESC
      Useful for getting current or forecast weather data
  
      The input to this tool should be a city name followed by the type of weather (current or forecast) you want to get, followed optionally by the units (imperial, metric, or standard)
      Example usage:
        Action Input: Boston, current, imperial
        Weather: The current weather in Boston is temp 52.47, feels_like 51.78, temp_min 48.56, temp_max 55.22, pressure 1006, humidity 93
    DESC

    attr_reader :client, :units

    #
    # Initializes the Weather tool
    #
    # @param api_key [String] Open Weather API key
    # @return [Langchain::Tool::Weather] Weather tool
    #
    def initialize(api_key:, units: "metric")
      depends_on "open-weather-ruby-client"
      require "open-weather-ruby-client"
      depends_on "geocoder"
      require "geocoder"

      OpenWeather::Client.configure do |config|
        config.api_key = api_key
        config.user_agent = "Langchainrb Ruby Client"
      end

      @client = OpenWeather::Client.new
    end

    #
    # Add advanced geocoding features. E.g., for locations other than cities.
    #
    # @param api_key [String] Geocoding API key
    #
    def add_geocoding(api_key:)
      # Configure geocoder here to use more advanced features like Google Premier API
      # Geocoder.configure(
      #   lookup: :google,
      #   api_key: api_key,
      #   use_https: true)
    end

    # Returns weather for a city
    # @param input [String] comma separated city, type of weather (current, forecast or historical), and unit (optional: imperial, metric, or standard)
    # @return [String] Answer
    def execute(input:)
      Langchain.logger.info("[#{self.class.name}]".light_blue + ": Executing for \"#{input}\"")

      input_array = input.split(",")
      city, type, units = *input_array.map(&:strip)

      if type === "current"
        data = client.current_weather(city: city, units: units)
        weather = data.main.map { |key, value| "#{key} #{value}" }.join(", ")
        "The current weather in #{data.name} is #{weather}"

      elsif type === "forecast"
        results = Geocoder.search(city)
        data = client.one_call(lat: results[0], lon: results[1], units: units, exclude: ["minutely", "hourly"])
        temp = data.daily.first.temp.day
        weather_desc = data.daily.first.weather.first.description
        "The forecast weather for is temperature #{temp} #{weather_desc}"
      else
        Langchain.logger.info("[#{self.class.name}]".light_blue + ": #{type} not yet implemented by this tool")
        "#{type} not yet implemented by this tool"
      end
    end
  end
end
