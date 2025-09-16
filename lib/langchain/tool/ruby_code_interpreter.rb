# frozen_string_literal: true

module LangChain::Tool
  #
  # A tool that execute Ruby code in a sandboxed environment.
  #
  # Gem requirements:
  #     gem "safe_ruby", "~> 1.0.5"
  #
  # Usage:
  #    interpreter = LangChain::Tool::RubyCodeInterpreter.new
  #
  class RubyCodeInterpreter
    extend LangChain::ToolDefinition
    include LangChain::DependencyHelper

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
    # @return [LangChain::Tool::Response] Answer
    def execute(input:)
      LangChain.logger.debug("#{self.class} - Executing \"#{input}\"")

      tool_response(content: safe_eval(input))
    end

    def safe_eval(code)
      SafeRuby.eval(code, timeout: @timeout)
    end
  end
end
