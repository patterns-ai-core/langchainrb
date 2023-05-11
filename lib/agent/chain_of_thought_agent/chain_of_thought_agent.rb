# frozen_string_literal: true

module Agent
  class ChainOfThoughtAgent < Base
    attr_reader :llm, :llm_api_key, :llm_client, :tools

    def initialize(llm:, llm_api_key:, tools: [])
      LLM::Base.validate_llm!(llm: llm)
      Tool::Base.validate_tools!(tools: tools)

      @llm = llm
      @llm_api_key = llm_api_key
      @tools = tools

      @llm_client = LLM.const_get(LLM::Base::LLMS.fetch(llm)).new(api_key: llm_api_key)
    end

    # Validate tools when they're re-assigned
    # @param value [Array] The tools to use
    def tools=(value)
      Tool::Base.validate_tools!(tools: value)
      @tools = value
    end

    # Run the Agent!
    # @param question [String] The question to ask
    # @param logging [Boolean] Whether or not to log the Agent's actions
    # @return [String] The answer to the question
    def run(question:, logging: false)
      question = question.strip
      prompt = create_prompt(
        question: question,
        tools: tools
      )

      loop do
        puts("Agent: Passing the prompt to the #{llm} LLM") if logging
        response = llm_client.generate_completion(
          prompt: prompt,
          stop_sequences: ["Observation:"],
          max_tokens: 500
        )

        # Append the response to the prompt
        prompt += response;
    
        # Find the requested action in the "Action: search" format
        action = response.match(/Action: (.*)/).try(:[], -1)
        
        if action
          # Find the input to the action in the "Action Input: [action_input]" format
          action_input = response.match(/Action Input: "?(.*)"?/).try(:[], -1)

          puts("Agent: Using the \"#{action}\" Tool with \"#{action_input}\"") if logging

          # Have the Tool execute with action_input
          result = Tool::Base::TOOLS[action.strip].constantize.execute(input: action_input)

          # Append the Observation to the prompt
          if prompt.end_with?("Observation:")
            prompt += " #{result}\nThought:"
          else
            prompt += "\nObservation: #{result}\nThought:"
          end
        else
          # Return the final answer
          break response.match(/Final Answer: (.*)/).try(:[], -1)
        end
      end
    end

    private

    # Create the initial prompt to pass to the LLM
    # @param question [String] Question to ask
    # @param tools [Array] Tools to use
    # @return [String] Prompt
    def create_prompt(question:, tools:)
      prompt_template.format(
        date: Date.today.strftime("%B %d, %Y"),
        question: question,
        tool_names: "[#{tools.join(", ")}]",
        tools: tools.map do |tool|
          "#{tool}: #{Tool::Base::TOOLS[tool].constantize.const_get("DESCRIPTION")}"
        end.join("\n")
      )
    end

    # Load the PromptTemplate from the JSON file
    # @return [PromptTemplate] PromptTemplate instance
    def prompt_template
      @template ||= Prompt.load_from_path(
        file_path: "lib/agent/chain_of_thought_agent/chain_of_thought_agent_prompt.json"
      )
    end
  end
end
