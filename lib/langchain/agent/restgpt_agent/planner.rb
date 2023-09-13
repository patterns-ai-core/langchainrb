# frozen_string_literal: true

require "pry-byebug"

module Langchain::Agent
  module RestGPTAgent
    class Planner
      attr_reader :llm, :prompt_template, :scenario

      def initialize(llm:, scenario:)
        @llm = llm
        @prompt_template = prompt_template
        @scenario = scenario
      end

      def call(input:, history: [])
        scratchpad = construct_scratchpad(history)
        # Uncomment the below line to enable printing of scratchpad
        # puts "Scrachpad: \n", scratchpad

        planner_prompt = prompt_template.format(
          agent_scratchpad: scratchpad,
          icl_examples: icl_examples[scenario], # Ensure icl_examples is defined and accessible
          input: input
        )

        planner_chain_output = llm.complete(prompt: planner_prompt, stop_sequences: stop)

        planner_chain_output = planner_chain_output.gsub(/Plan step \d+: /, "").strip

        {"result" => planner_chain_output}
      end

      private

      # Load the PromptTemplate from the YAML file
      # @return [PromptTemplate] PromptTemplate instance
      def prompt_template
        @template ||= Langchain::Prompt.load_from_path(
          file_path: Langchain.root.join("langchain/agent/restgpt_agent/prompts/planner.yaml")
        )
      end

      # Prefix to append the observation with.
      def observation_prefix
        "API response: "
      end

      # Prefix to append the llm call with.
      def llm_prefix
        "Plan step {}: "
      end

      def stop
        [
          "\n#{observation_prefix.rstrip}",
          "\n\t#{observation_prefix.rstrip}",
        ]
      end

      def construct_scratchpad(history)
        return "" if history.empty?

        scratchpad = ""
        history.each_with_index do |(plan, execution_res), i|
          scratchpad += llm_prefix % (i + 1) + plan["result"] + "\n"
          scratchpad += observation_prefix + execution_res["result"] + "\n"
        end
        scratchpad
      end

      def icl_examples
        {
          "tmdb": """Example 1:
            User query: give me some movies performed by Tony Leung.
            Plan step 1: search person with name 'Tony Leung'
            API response: Tony Leung's person_id is 1337
            Plan step 2: collect the list of movies performed by Tony Leung whose person_id is 1337
            API response: Shang-Chi and the Legend of the Ten Rings, In the Mood for Love, Hero
            Thought: I am finished executing a plan and have the information the user asked for or the data the used asked to create
            Final Answer: Tony Leung has performed in Shang-Chi and the Legend of the Ten Rings, In the Mood for Love, Hero

            Example 2:
            User query: Who wrote the screenplay for the most famous movie directed by Martin Scorsese?
            Plan step 1: search for the most popular movie directed by Martin Scorsese
            API response: Successfully called GET /search/person to search for the director 'Martin Scorsese'. The id of Martin Scorsese is 1032
            Plan step 2: Continue. search for the most popular movie directed by Martin Scorsese (1032)
            API response: Successfully called GET /person/{{person_id}}/movie_credits to get the most popular movie directed by Martin Scorsese. The most popular movie directed by Martin Scorsese is Shutter Island (11324)
            Plan step 3: search for the screenwriter of Shutter Island
            API response: The screenwriter of Shutter Island is Laeta Kalogridis (20294)
            Thought: I am finished executing a plan and have the information the user asked for or the data the used asked to create
            Final Answer: Laeta Kalogridis wrote the screenplay for the most famous movie directed by Martin Scorsese.
          """,
          "spotify": """Example 1:
            User query: set the volume to 20 and skip to the next track.
            Plan step 1: set the volume to 20
            API response: Successfully called PUT /me/player/volume to set the volume to 20.
            Plan step 2: skip to the next track
            API response: Successfully called POST /me/player/next to skip to the next track.
            Thought: I am finished executing a plan and completed the user's instructions
            Final Answer: I have set the volume to 20 and skipped to the next track.

            Example 2:
            User query: Make a new playlist called 'Love Coldplay' containing the most popular songs by Coldplay
            Plan step 1: search for the most popular songs by Coldplay
            API response: Successfully called GET /search to search for the artist Coldplay. The id of Coldplay is 4gzpq5DPGxSnKTe4SA8HAU
            Plan step 2: Continue. search for the most popular songs by Coldplay (4gzpq5DPGxSnKTe4SA8HAU)
            API response: Successfully called GET /artists/4gzpq5DPGxSnKTe4SA8HAU/top-tracks to get the most popular songs by Coldplay. The most popular songs by Coldplay are Yellow (3AJwUDP919kvQ9QcozQPxg), Viva La Vida (1mea3bSkSGXuIRvnydlB5b).
            Plan step 3: make a playlist called 'Love Coldplay'
            API response: Successfully called GET /me to get the user id. The user id is xxxxxxxxx.
            Plan step 4: Continue. make a playlist called 'Love Coldplay'
            API response: Successfully called POST /users/xxxxxxxxx/playlists to make a playlist called 'Love Coldplay'. The playlist id is 7LjHVU3t3fcxj5aiPFEW4T.
            Plan step 5: Add the most popular songs by Coldplay, Yellow (3AJwUDP919kvQ9QcozQPxg), Viva La Vida (1mea3bSkSGXuIRvnydlB5b), to playlist 'Love Coldplay' (7LjHVU3t3fcxj5aiPFEW4T)
            API response: Successfully called POST /playlists/7LjHVU3t3fcxj5aiPFEW4T/tracks to add Yellow (3AJwUDP919kvQ9QcozQPxg), Viva La Vida (1mea3bSkSGXuIRvnydlB5b) in playlist 'Love Coldplay' (7LjHVU3t3fcxj5aiPFEW4T). The playlist id is 7LjHVU3t3fcxj5aiPFEW4T.
            Thought: I am finished executing a plan and have the data the used asked to create
            Final Answer: I have made a new playlist called 'Love Coldplay' containing Yellow and Viva La Vida by Coldplay.
          """
        }
      end
    end
  end
end
