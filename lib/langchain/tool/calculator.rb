# frozen_string_literal: true

module Langchain::Tool
  class Calculator < Base
    attr_reader :llm
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
    DESC

    def initialize(llm: nil)
      depends_on "eqn"
      require "eqn"

      @llm = llm
    end

    # Evaluates a pure math expression or if equation contains non-math characters (e.g.: "12F in Celsius") then
    # it uses the llm to generate a math expression from the input and then evaluates it.
    # @param input [String] math expression
    # @return [String] Answer
    def execute(input:, count: 0)
      raise "Too many attempts" if count > 5
      Langchain.logger.info("[#{self.class.name}]".light_blue + ": Executing \"#{input}\"")

      Eqn::Calculator.calc(input)
    rescue Eqn::ParseError, Eqn::NoVariableValueError => e
      if llm
        output = llm.complete(
          prompt: PROMPT_TEMPLATE % {question: input}
        )
        expression = output.strip.match(/```text(.*)```/m)[1].strip
        execute(input: expression, count: count + 1)
      else
        raise e
      end
    end
  end
end

PROMPT_TEMPLATE = "" "Translate a math problem into a expression that can be executed using Ruby's Eqn library. Use the output of running this code to answer the question.

Question: ${{Question with math problem.}}
```text
${{single line mathematical expression that solves the problem}}
```

Begin.

Question: What is 37593 * 67?

```text
37593 * 67
```

Question: %{question}
" ""
