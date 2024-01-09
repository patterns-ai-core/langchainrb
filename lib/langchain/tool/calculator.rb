# frozen_string_literal: true

module Langchain::Tool
  class Calculator < Base
    #
    # A calculator tool that falls back to the Google calculator widget
    #
    # Gem requirements:
    #   gem "eqn", "~> 1.6.5"
    #   gem "google_search_results", "~> 2.0.0"
    #

    NAME = "calculator"

    description <<~DESC
      Useful for getting the result of a math expression.

      The input to this tool should be a valid mathematical expression that could be executed by a simple calculator.
      Usage:
        Action Input: 1 + 1
        Action Input: 3 * 2 / 4
        Action Input: 9 - 7
        Action Input: (4.1 + 2.3) / (2.0 - 5.6) * 3
    DESC

    def initialize
      depends_on "eqn"
    end

    # Evaluates a pure math expression or if equation contains non-math characters (e.g.: "12F in Celsius") then
    # it uses the google search calculator to evaluate the expression
    # @param input [String] math expression
    # @return [String] Answer
    def execute(input:)
      Langchain.logger.info("Executing \"#{input}\"", for: self.class)

      Eqn::Calculator.calc(input)
    rescue Eqn::ParseError, Eqn::NoVariableValueError
      "\"#{input}\" is an invalid mathematical expression"
    end
  end
end
