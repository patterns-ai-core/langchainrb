# frozen_string_literal: true

module Langchain::Agent
  class ChainOfThoughtAgent < Base
    attr_reader :llm, :tools

    # Initializes the Agent
    #
    # @param llm [Object] The LLM client to use
    # @param tools [Array] The tools to use
    # @return [ChainOfThoughtAgent] The Agent::ChainOfThoughtAgent instance
    def initialize(llm:, tools: [])
      Langchain::Tool::Base.validate_tools!(tools: tools)

      @tools = tools

      @llm = llm
    end

    # Validate tools when they're re-assigned
    #
    # @param value [Array] The tools to use
    # @return [Array] The tools that will be used
    def tools=(value)
      Langchain::Tool::Base.validate_tools!(tools: value)
      @tools = value
    end

    # Run the Agent!
    #
    # @param question [String] The question to ask
    # @return [String] The answer to the question
    def run(question:)
      question = question.strip
      prompt = create_prompt(
        question: question,
        tools: tools
      )

      loop do
        Langchain.logger.info("[#{self.class.name}]".red + ": Sending the prompt to the #{llm.class} LLM")

        response = llm.complete(prompt: prompt, stop_sequences: ["Observation:"])

        # Append the response to the prompt
        prompt += response

        # Find the requested action in the "Action: search" format
        action = response.match(/Action: (.*)/)&.send(:[], -1)

        if action
          # Find the input to the action in the "Action Input: [action_input]" format
          action_input = response.match(/Action Input: "?(.*)"?/)&.send(:[], -1)

          # Find the Tool and call `execute`` with action_input as the input
          tool = tools.find { |tool| tool.tool_name == action.strip }
          Langchain.logger.info("[#{self.class.name}]".red + ": Invoking \"#{tool.class}\" Tool with \"#{action_input}\"")

          # Call `execute` with action_input as the input
          result = tool.execute(input: action_input)

          # Append the Observation to the prompt
          prompt += if prompt.end_with?("Observation:")
            " #{result}\nThought:"
          else
            "\nObservation: #{result}\nThought:"
          end
        else
          # Return the final answer
          break response.match(/Final Answer: (.*)/)&.send(:[], -1)
        end
      end
    end

    private

    # Create the initial prompt to pass to the LLM
    # @param question [String] Question to ask
    # @param tools [Array] Tools to use
    # @return [String] Prompt
    def create_prompt(question:, tools:)
      tool_list = tools.map(&:tool_name)

      prompt_template.format(
        date: Date.today.strftime("%B %d, %Y"),
        question: question,
        tool_names: "[#{tool_list.join(", ")}]",
        tools: tools.map do |tool|
          tool_name = tool.tool_name
          tool_description = tool.class.const_get(:DESCRIPTION)
          "#{tool_name}: #{tool_description}"
        end.join("\n")
      )
    end

    # Load the PromptTemplate from the JSON file
    # @return [PromptTemplate] PromptTemplate instance
    def prompt_template
      @template ||= Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/agent/chain_of_thought_agent/chain_of_thought_agent_prompt.json")
      )
    end
  end
end
