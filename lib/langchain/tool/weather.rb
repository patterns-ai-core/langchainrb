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
    # @param input [String] city + ',' + type of weather (current, forecast or historical) + unit (optional: imperial, metric, or standard)
    # @return [String] Answer
    def execute(input:)
      Langchain.logger.info("[#{self.class.name}]".light_blue + ": Executing for \"#{input}\"")

      if input.count(",") > 1
        units = input.split(", ").last
        type = input.split(", ")[0..-2][1]
      else
        type = input.split(", ").last
      end

      if type === "current"
        data = client.current_weather(city: input.split(", ").first, units: units)
        weather = data.main.map { |key, value| "#{key} #{value}" }.join(", ")
        "The current weather in #{data.name} is #{weather}"
      elsif type === "forecast"
        # TODO: data = client.one_call(lat: 33.441792, lon: -94.037689) # => OpenWeather::Models::OneCall::Weather
        "forcasts coming soon from this tool"
      else
        # TODO: Do we support this? It's only available for paid OpenWeather accounts.
        "#{type} not yet implemented by this tool"
      end
    end
  end
end
