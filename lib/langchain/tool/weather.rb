# frozen_string_literal: true

module Langchain::Tool
  class Weather < Base
    #
    # A weather tool that gets current, forecast, or historical weather data
    #
    # Gem requirements:
    #   gem "open-weather-ruby-client", "~> 0.3.0"
    #

    NAME = "weather"

    description <<~DESC
      Useful for getting current, forecast, or historical weather data
  
      The input to this tool should be a city name followed by the type of weather you want to get.
    DESC

    attr_reader :client

    def initialize(api_key:)
      depends_on "open-weather-ruby-client"
      require "open-weather-ruby-client"

      OpenWeather::Client.configure do |config|
        config.api_key = api_key
        config.user_agent = "Langchainrb Ruby Client"
      end

      @client = OpenWeather::Client.new
    end

    # Returns weather for a city
    # @param input [String] city + type of weather (current, forecast or historical)
    # @return [String] Answer
    def execute(input:)
      Langchain.logger.info("[#{self.class.name}]".light_blue + ": Executing for \"#{input}\"")

      type = input.split(", ").last

      if type === "current"
        data = client.current_weather(city: input.split(", ").first)
        "The current weather in #{data.name} is #{data.main.temp} degrees Farenheit"
      else
        "#{type} not yet implemented"
      end
    end
  end
end
