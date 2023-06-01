# frozen_string_literal: true

module Tool
  class CodeInterpreter < Base
    description <<~DESC
      Useful for executing ruby code.
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
