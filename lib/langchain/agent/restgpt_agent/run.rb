# frozen_string_literal: true

module Langchain::Agent
  module RestGPTAgent
    class Run
      # require 'spotipy'

      def start(scenario)
        # print "Please select a scenario (TMDB/Spotify): "
        # scenario = gets.chomp.downcase

        if scenario == 'tmdb'
          raw_api_spec = JSON.parse(File.read('specs/tmdb_oas.json'))
          api_spec = reduce_openapi_spec(raw_api_spec, only_required: false)

          access_token = ENV['TMDB_ACCESS_TOKEN']
          headers = { 'Authorization' => "Bearer #{access_token}" }
        elsif scenario == 'spotify'
          raw_api_spec = JSON.parse(File.read('specs/spotify_oas.json'))
          api_spec = reduce_openapi_spec(raw_api_spec, only_required: false, merge_allof: true)

          scopes = raw_api_spec['components']['securitySchemes']['oauth_2_0']['flows']['authorizationCode']['scopes'].keys.join(',')
          access_token = Spotipy.util.prompt_for_user_token(scope: scopes)
          headers = { 'Authorization' => "Bearer #{access_token}" }
        else
          raise "Unsupported scenario: #{scenario}"
        end

        requests_wrapper = Faraday.new(headers: headers)

        llm = OpenAI.new(model_name: 'text-davinci-003', temperature: 0.0, max_tokens: 700)
        rest_gpt = Langchain::Agent::RestGPTAgent::Main.new(llm, api_spec: api_spec, scenario: scenario, requests_wrapper: requests_wrapper, simple_parser: false)

        query_example = scenario == 'tmdb' ? 'Give me the number of movies directed by Sofia Coppola' : 'Add Summertime Sadness by Lana Del Rey in my first playlist'

        puts "Example instruction: #{query_example}"
        print "Please input an instruction (Press ENTER to use the example instruction): "
        query = gets.chomp
        query = query_example if query.empty?

        logger.info("Query: #{query}")

        start_time = Time.now
        rest_gpt.run(query)
        logger.info("Execution Time: #{Time.now - start_time}")
      end
    end
  end
end
