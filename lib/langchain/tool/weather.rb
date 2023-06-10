# frozen_string_literal: true

module Langchain::Tool
  class Weather < Base
    #
    # A weather tool that gets current, forecast, or historical weather data
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
      Useful for getting current, forecast, or historical weather data
  
      The input to this tool should be a city name followed by the type of weather (current or forecast) you want to get, followed optionally by the units (imperial, metric, or standard)
      Example usage:
        Action Input: Boston, current, imperial
        Weather: The current weather in Boston is temp 52.47, feels_like 51.78, temp_min 48.56, temp_max 55.22, pressure 1006, humidity 93
    DESC

    attr_reader :client, :units

    def initialize(api_key:, units: "metric")
      depends_on "open-weather-ruby-client"
      require "open-weather-ruby-client"

      OpenWeather::Client.configure do |config|
        config.api_key = api_key
        config.user_agent = "Langchainrb Ruby Client"
      end

      @client = OpenWeather::Client.new
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
        # TODO: Get city lat/lon from city name in order to get forecast using following example code:
        #       data = client.one_call(lat: 33.441792, lon: -94.037689) # => OpenWeather::Models::OneCall::Weather
        Langchain.logger.warn("[#{self.class.name}]".light_blue + ": TODO: Implement forecast")
        "forecasts coming soon from this tool"
      else
        # TODO: Do we support 'historical' input type here? It is only available for paid OpenWeather accounts:
        #       data = client.one_call(lat: 33.441792, lon: -94.037689, dt: Time.now - 24 * 60 * 60)
        Langchain.logger.info("[#{self.class.name}]".light_blue + ": #{type} not yet implemented by this tool")
        "#{type} not yet implemented by this tool"
      end
    end
  end
end
