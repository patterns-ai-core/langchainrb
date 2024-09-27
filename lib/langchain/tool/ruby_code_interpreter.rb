# frozen_string_literal: true

module Langchain::Tool
  #
  # A tool that execute Ruby code in a sandboxed environment.
  #
  # Gem requirements:
  #     gem "safe_ruby", "~> 1.0.4"
  #
  # Usage:
  #    interpreter = Langchain::Tool::RubyCodeInterpreter.new
  #
  class RubyCodeInterpreter
    extend Langchain::ToolDefinition
    include Langchain::DependencyHelper

    define_function :execute, description: "Executes Ruby code in a sandboxes environment" do
      property :input, type: "string", description: "Ruby code expression", required: true
    end

    def initialize(timeout: 30)
      depends_on "safe_ruby"

      @timeout = timeout
    end

    # Executes Ruby code in a sandboxes environment.
    #
    # @param input [String] ruby code expression
    # @return [String] Answer
    def execute(input:)
      Langchain.logger.debug("#{self.class} - Executing \"#{input}\"")

      safe_eval(input)
    end

    def safe_eval(code)
      SafeRuby.eval(code, timeout: @timeout)
    end
  end
end
