# frozen_string_literal: true

module Langchain::Tool
  #
  # A calculator tool that falls back to the Google calculator widget
  #
  # Gem requirements:
  #     gem "eqn", "~> 1.6.5"
  #     gem "google_search_results", "~> 2.0.0"
  #
  # Usage:
  #     calculator = Langchain::Tool::Calculator.new
  #
  class Calculator
    extend Langchain::ToolDefinition
    include Langchain::DependencyHelper

    define_function :execute, description: "Evaluates a pure math expression or if equation contains non-math characters (e.g.: \"12F in Celsius\") then it uses the google search calculator to evaluate the expression" do
      property :input, type: "string", description: "Math expression", required: true
    end

    def initialize
      depends_on "eqn"
    end

    # Evaluates a pure math expression or if equation contains non-math characters (e.g.: "12F in Celsius") then it uses the google search calculator to evaluate the expression
    #
    # @param input [String] math expression
    # @return [String] Answer
    def execute(input:)
      Langchain.logger.debug("#{self.class} - Executing \"#{input}\"")

      Eqn::Calculator.calc(input)
    rescue Eqn::ParseError, Eqn::NoVariableValueError
      "\"#{input}\" is an invalid mathematical expression"
    end
  end
end
