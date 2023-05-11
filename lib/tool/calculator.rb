# frozen_string_literal: true

require "eqn"

module Tool
  class Calculator < Base
    DESCRIPTION = "Useful for getting the result of a math expression. "
      "The input to this tool should be a valid mathematical expression that could be executed by a simple calculator."

    def self.execute(input:)
      Eqn::Calculator.calc(input)
    rescue Eqn::ParseError
      # Sometimes the input is not a pure math expression, e.g: "12F in Celsius"
      # We can use the google answer box to evaluate this expression
      Tool::SerpApi.calculate(input: input)
    end
  end
end
