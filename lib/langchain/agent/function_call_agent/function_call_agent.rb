# frozen_string_literal: true

module Langchain::Agent
  class FunctionCallAgent < Base
    attr_reader :conversation, :tools

    #
    # Initializes the Agent
    #
    # @param llm [Object] The LLM client to use
    # @param tools [Array<Object>] The tools that can be invoked
    #
    def initialize(llm:, tools:)
      Langchain::Tool::Base.validate_tools!(tools: tools)

      @conversation = Langchain::Conversation.new(llm: llm)
      @tools = tools
    end

    #
    # Ask a question and responds or call the appropriate function
    #
    # @param question [String] Question to ask the LLM
    # @return [String] Answer to the question
    #
    def run(question:)
      conversation.set_functions(tools.map(&:schema))
      ai_response = conversation.message(question)

      if (function = ai_response.additional_kwargs[:function_call])
        tool = tools.find { |tool| tool.name == function["name"] }
        tool.execute(**JSON.parse(function["arguments"]).transform_keys(&:to_sym)).tap do |result|
          conversation.add_function_call_result(function["name"], result)
        end
      else
        ai_response.content
      end
    end
  end
end
