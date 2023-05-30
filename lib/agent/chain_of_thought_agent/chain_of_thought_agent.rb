# frozen_string_literal: true

module Agent
  # Represents an agent that uses a Chain of Thought approach to answer questions
  class ChainOfThoughtAgent < Base
    attr_reader :llm, :llm_api_key, :llm_client, :tools

    # Initializes the Agent
    #
    # @param llm [Symbol] The LLM to use
    # @param llm_api_key [String] The API key for the LLM
    # @param tools [Array] The tools to use
    # @return [ChainOfThoughtAgent] The Agent::ChainOfThoughtAgent instance
    def initialize(llm:, llm_api_key:, tools: [])
      LLM::Base.validate_llm!(llm:)
      Tool::Base.validate_tools!(tools:)

      @llm = llm
      @llm_api_key = llm_api_key
      @tools = tools

      @llm_client = LLM.const_get(LLM::Base::LLMS.fetch(llm)).new(api_key: llm_api_key)
    end

    # Validate tools when they're re-assigned
    #
    # @param value [Array] The tools to use
    # @return [Array] The tools that will be used
    def tools=(value)
      Tool::Base.validate_tools!(tools: value)
      @tools = value
    end

    # Run the Agent!
    #
    # @param question [String] The question to ask
    # @return [String] The answer to the question
    def run(question:)
      @prompt = prepare_prompt(question)

      loop do
        response = generate_llm_response
        append_response_to_prompt(response)
        action = extract_action(response)

        break extract_final_answer(response) unless action

        execute_tool_action(action, response)
      end
    end

    private

    def extract_final_answer(response)
      response.match(/Final Answer: (.*)/)&.send(:[], -1)
    end

    def execute_tool_action(action, response)
      action_input = extract_action_input(response)
      log_tool_usage(action, action_input)
      result = execute_tool(action, action_input)
      append_observation_to_prompt(result)
    end

    def log_tool_usage(action, action_input)
      Langchain.logger.info("Agent: Using the \"#{action}\" Tool with \"#{action_input}\"")
    end

    def execute_tool(action, action_input)
      Tool
        .const_get(Tool::Base::TOOLS[action.strip])
        .execute(input: action_input)
    end

    def extract_action_input(response)
      response.match(/Action Input: "?(.*)"?/)&.send(:[], -1)
    end

    def append_observation_to_prompt(result)
      @prompt += if @prompt.end_with?("Observation:")
        " #{result}\nThought:"
      else
        "\nObservation: #{result}\nThought:"
      end
    end

    def extract_action(response)
      response.match(/Action: (.*)/)&.send(:[], -1)
    end

    def append_response_to_prompt(response)
      @prompt += response
    end

    def generate_llm_response
      log_llm_prompt_passing
      llm_client.complete(
        prompt: @prompt,
        stop_sequences: ["Observation:"],
        max_tokens: 500
      )
    end

    def log_llm_prompt_passing
      Langchain.logger.info("Agent: Passing the prompt to the #{llm} LLM")
    end

    def prepare_prompt(question)
      question = question.strip
      create_prompt(
        question:,
        tools:
      )
    end

    # Create the initial prompt to pass to the LLM
    # @param question [String] Question to ask
    # @param tools [Array] Tools to use
    # @return [String] Prompt
    def create_prompt(question:, tools:)
      prompt_template.format(
        date: Date.today.strftime("%B %d, %Y"),
        question:,
        tool_names: "[#{tools.join(", ")}]",
        tools: tools.map do |tool|
          "#{tool}: #{Tool.const_get(Tool::Base::TOOLS[tool]).const_get(:DESCRIPTION)}"
        end.join("\n")
      )
    end

    # Load the PromptTemplate from the JSON file
    # @return [PromptTemplate] PromptTemplate instance
    def prompt_template
      @template ||= Prompt.load_from_path(
        file_path: Langchain.root.join("agent/chain_of_thought_agent/chain_of_thought_agent_prompt.json")
      )
    end
  end
end
