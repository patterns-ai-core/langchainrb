# frozen_string_literal: true

module Langchain::Tool
  class RubyCodeInterpreter < Base
    description <<~DESC
      A Ruby code interpreter. Use this to execute ruby expressions. Input should be a valid ruby expression. If you want to see the output of the tool, make sure to return a value.
    DESC

    def initialize(timeout: 30)
      @timeout = timeout
      depends_on "safe_ruby"
      require "safe_ruby"
    end

    # @param input [String] ruby code expression
    # @return [String] Answer
    def execute(input:)
      safe_eval(input)
    end

    def safe_eval(code)
      SafeRuby.eval(code, timeout: @timeout)
    end
  end
end
