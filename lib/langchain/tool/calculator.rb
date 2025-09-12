# frozen_string_literal: true

module LangChain::Tool
  #
  # A calculator tool
  #
  # Gem requirements:
  #     gem "eqn", "~> 1.6.5"
  #
  # Usage:
  #     calculator = LangChain::Tool::Calculator.new
  #
  class Calculator
    extend LangChain::ToolDefinition
    include LangChain::DependencyHelper

    define_function :execute, description: "Evaluates a pure math expression" do
      property :input, type: "string", description: "Math expression", required: true
    end

    def initialize
      depends_on "eqn"
    end

    # Evaluates a pure math expression
    #
    # @param input [String] math expression
    # @return [LangChain::Tool::Response] Answer
    def execute(input:)
      LangChain.logger.debug("#{self.class} - Executing \"#{input}\"")

      result = Eqn::Calculator.calc(input)
      tool_response(content: result)
    rescue Eqn::ParseError, Eqn::NoVariableValueError
      tool_response(content: "\"#{input}\" is an invalid mathematical expression")
    end
  end
end
