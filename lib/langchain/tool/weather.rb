# frozen_string_literal: true

module Langchain::Tool
  #
  # A weather tool that gets current weather data
  #
  # Current weather data is free for 1000 calls per day (https://home.openweathermap.org/api_keys)
  # Forecast and historical data require registration with credit card, so not supported yet.
  #
  # Usage:
  #     weather = Langchain::Tool::Weather.new(api_key: ENV["OPEN_WEATHER_API_KEY"])
  #     assistant = Langchain::Assistant.new(
  #       llm: llm,
  #       tools: [weather]
  #     )
  #
  class Weather
    extend Langchain::ToolDefinition

    define_function :get_current_weather, description: "Returns current weather for a city" do
      property :city,
        type: "string",
        description: "City name",
        required: true
      property :state_code,
        type: "string",
        description: "State code",
        required: true
      property :country_code,
        type: "string",
        description: "Country code",
        required: false
      property :units,
        type: "string",
        description: "Units for temperature (imperial or metric). Default: \"imperial\"",
        enum: ["imperial", "metric", "standard"],
        required: false
    end

    def initialize(api_key:)
      @api_key = api_key
    end

    def get_current_weather(city:, state_code:, country_code: nil, units: "imperial")
      validate_input(city: city, state_code: state_code, country_code: country_code, units: units)

      Langchain.logger.debug("#{self.class} - get_current_weather #{{city:, state_code:, country_code:, units:}}")

      fetch_current_weather(city: city, state_code: state_code, country_code: country_code, units: units)
    end

    private

    def fetch_current_weather(city:, state_code:, country_code:, units:)
      params = {appid: @api_key, q: [city, state_code, country_code].compact.join(","), units: units}

      location_response = send_request(path: "geo/1.0/direct", params: params.except(:units))
      return location_response if location_response.is_a?(String) # Error occurred

      location = location_response.first
      return "Location not found" unless location

      params = params.merge(lat: location["lat"], lon: location["lon"]).except(:q)
      weather_data = send_request(path: "data/2.5/weather", params: params)

      parse_weather_response(weather_data, units)
    end

    def send_request(path:, params:)
      uri = URI.parse("https://api.openweathermap.org/#{path}?#{URI.encode_www_form(params)}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      request["Content-Type"] = "application/json"

      Langchain.logger.debug("#{self.class} - Sending request to OpenWeatherMap API #{{path: path, params: params.except(:appid)}}")
      response = http.request(request)
      Langchain.logger.debug("#{self.class} - Received response from OpenWeatherMap API #{{status: response.code}}")

      if response.code == "200"
        JSON.parse(response.body)
      else
        "API request failed: #{response.code} - #{response.message}"
      end
    end

    def validate_input(city:, state_code:, country_code:, units:)
      raise ArgumentError, "City name cannot be empty" if city.to_s.strip.empty?
      raise ArgumentError, "State code cannot be empty" if state_code.to_s.strip.empty?
      raise ArgumentError, "Invalid units. Use \"imperial\", \"standard\" or \"metric\"" unless ["imperial", "metric", "standard"].include?(units)
    end

    def parse_weather_response(response, units)
      temp_unit = case units
      when "standard" then "K"
      when "metric" then "°C"
      when "imperial" then "°F"
      end
      speed_unit = (units == "imperial") ? "mph" : "m/s"
      {
        temperature: "#{response["main"]["temp"]} #{temp_unit}",
        humidity: "#{response["main"]["humidity"]}%",
        description: response["weather"][0]["description"],
        wind_speed: "#{response["wind"]["speed"]} #{speed_unit}"
      }
    end
  end
end
