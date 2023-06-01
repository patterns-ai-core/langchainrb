# frozen_string_literal: true

module Langchain::Tool
  class Calculator < Base
    description <<~DESC
      Useful for getting the result of a math expression.

      The input to this tool should be a valid mathematical expression that could be executed by a simple calculator.
    DESC

    def initialize
      depends_on "eqn"
      require "eqn"
    end

    # Evaluates a pure math expression or if equation contains non-math characters (e.g.: "12F in Celsius") then
    # it uses the google search calculator to evaluate the expression
    # @param input [String] math expression
    # @return [String] Answer
    def execute(input:)
      Eqn::Calculator.calc(input)
    rescue Eqn::ParseError, Eqn::NoVariableValueError
      # Sometimes the input is not a pure math expression, e.g: "12F in Celsius"
      # We can use the google answer box to evaluate this expression
      hash_results = Langchain::Tool::SerpApi.execute_search(input: input)
      hash_results.dig(:answer_box, :to)
    end
  end
end
