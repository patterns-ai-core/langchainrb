# frozen_string_literal: true

module Langchain::Agent
  module RestGPTAgent
    class APISelector
      include Langchain::Agent::RestGPTAgent::Utils

      attr_reader :llm, :prompt_template, :api_selector_prompt, :scenario, :api_spec, :output_key, :api_name_desc

      SPOTIFY_OAS = JSON.parse(File.read(Langchain.root.join("langchain/agent/restgpt_agent/specs/spotify_oas.json")))
      TMDB_OAS = JSON.parse(File.read(Langchain.root.join("langchain/agent/restgpt_agent/specs/tmdb_oas.json")))

      def initialize(llm:, scenario:, api_spec: nil)
        @llm = llm
        @scenario = scenario
        @api_spec = reduce_openapi_spec(TMDB_OAS)

        @api_name_desc = @api_spec.endpoints.map { |endpoint| "#{endpoint[0]} #{endpoint[1]&.split(".")&.first || ""}" }
        @api_name_desc = @api_name_desc.join("\n")

        @api_selector_prompt = prompt_template
        @output_key = "result"
      end

      def call(plan:, background:, history: [], instruction: "")
        scratchpad = history ? construct_scratchpad(history, instruction) : ""

        prompt = api_selector_prompt.format(
          endpoints: api_name_desc,
          icl_examples: icl_examples[scenario], # Ensure icl_examples is defined and accessible
          plan: plan,
          background: background,
          agent_scratchpad: scratchpad
        )

        api_selector_chain_output = llm.complete(prompt: prompt, stop_sequences: stop)

        api_plan = api_selector_chain_output.gsub(/API calling \d+: /, "").strip

        Langchain.logger.info("API Selector: #{api_plan}") # Ensure logger is defined and accessible

        finish = /No API call needed\.(.*)/.match(api_plan)
        return {"result" => api_plan} if finish

        while get_matched_endpoint(api_spec, api_plan).nil? # Ensure get_matched_endpoint method is defined and accessible
          Langchain.logger.info("API Selector: The API you called is not in the list of available APIs. Please use another API.")
          scratchpad += "#{api_selector_chain_output}\nThe API you called is not in the list of available APIs. Please use another API.\n"
          api_selector_chain_output = api_selector_chain.run(plan: plan, background: background, agent_scratchpad: scratchpad, stop: stop)
          api_plan = api_selector_chain_output.gsub(/API calling \d+: /, "").strip
          Langchain.logger.info("API Selector: #{api_plan}")
        end

        {"result" => api_plan}
      end

      private

      # Load the PromptTemplate from the YAML file
      # @return [PromptTemplate] PromptTemplate instance
      def prompt_template
        @template ||= Langchain::Prompt.load_from_path(
          file_path: Langchain.root.join("langchain/agent/restgpt_agent/prompts/api_selector.yaml")
        )
      end

      # Prefix to append the observation with.
      def observation_prefix
        "API response: "
      end

      def stop
        [
          "\n#{observation_prefix.rstrip}",
          "\n\t#{observation_prefix.rstrip}",
        ]
      end

      def construct_scratchpad(history, instruction)
        return "" if history.empty?

        scratchpad = ""
        history.each_with_index do |(plan, api_plan, execution_res), i|
          scratchpad += "Instruction: #{plan}\n" if i != 0
          scratchpad += llm_prefix % (i + 1) + api_plan + "\n"
          scratchpad += observation_prefix + execution_res + "\n"
        end
        scratchpad += "Instruction: #{instruction}\n"
        scratchpad
      end

      def icl_examples = {
        "tmdb": """Example 1:
            Background: The id of Wong Kar-Wai is 12453
            User query: give me the latest movie directed by Wong Kar-Wai.
            API calling 1: GET /person/12453/movie_credits to get the latest movie directed by Wong Kar-Wai (id 12453)
            API response: The latest movie directed by Wong Kar-Wai is The Grandmaster (id 44865), ...

            Example 2:

            Background: No background
            User query: search for movies produced by DreamWorks Animation
            API calling 1: GET /search/company to get the id of DreamWorks Animation
            API response: DreamWorks Animation's company_id is 521
            Instruction: Continue. Search for the movies produced by DreamWorks Animation
            API calling 2: GET /discover/movie to get the movies produced by DreamWorks Animation
            API response: Puss in Boots: The Last Wish (id 315162), Shrek (id 808), The Bad Guys (id 629542), ...

            Example 3:

            Background: The id of the movie Happy Together is 18329
            User query: search for the director of Happy Together
            API calling 1: GET /movie/18329/credits to get the director for the movie Happy Together
            API response: The director of Happy Together is Wong Kar-Wai (12453)

            Example 4:

            Background: No background
            User query: search for the highest rated movie directed by Wong Kar-Wai
            API calling 1: GET /search/person to search for Wong Kar-Wai
            API response: The id of Wong Kar-Wai is 12453
            Instruction: Continue. Search for the highest rated movie directed by Wong Kar-Wai (id 12453)
            API calling 2: GET /person/12453/movie_credits to get the highest rated movie directed by Wong Kar-Wai (id 12453)
            API response: The highest rated movie directed by Wong Kar-Wai is In the Mood for Love (id 843), ...
        """,
        "spotify": """Example 1:
          Background: No background
          User query: what is the id of album Kind of Blue.
          API calling 1: GET /search to search for the album 'Kind of Blue'
          API response: Kind of Blue's album_id is 1weenld61qoidwYuZ1GESA

          Example 2:
          Background: No background
          User query: get the newest album of Lana Del Rey (id 00FQb4jTyendYWaN8pK0wa).
          API calling 1: GET /artists/00FQb4jTyendYWaN8pK0wa/albums to get the newest album of Lana Del Rey (id 00FQb4jTyendYWaN8pK0wa)
          API response: The newest album of Lana Del Rey is Did you know that there's a tunnel under Ocean Blvd (id 5HOHne1wzItQlIYmLXLYfZ), ...

          Example 3:
          Background: The ids and names of the tracks of the album 1JnjcAIKQ9TSJFVFierTB8 are Yellow (3AJwUDP919kvQ9QcozQPxg), Viva La Vida (1mea3bSkSGXuIRvnydlB5b)
          User query: append the first song of the newest album 1JnjcAIKQ9TSJFVFierTB8 of Coldplay (id 4gzpq5DPGxSnKTe4SA8HAU) to my player queue.
          API calling 1: POST /me/player/queue to add Yellow (3AJwUDP919kvQ9QcozQPxg) to the player queue
          API response: Yellow is added to the player queue
        """
      }
    end
  end
end
