# frozen_string_literal: true

module Langchain::OutputParsers
  # Structured output parsers from the LLM.
  #
  # @abstract
  class Base
    #
    # Parse the output of an LLM call.
    #
    # @param text - LLM output to parse.
    # @returns Parsed output.
    #
    def parse(text:)
      raise NotImplementedError
    end

    #
    # Return a string describing the format of the output.
    #
    # @returns Format instructions.
    # @param options - Options for formatting instructions.
    # @example
    # ```json
    # {
    #  "foo": "bar"
    # }
    # ```
    #
    def get_format_instructions
      raise NotImplementedError
    end
  end

  class OutputParserException < StandardError
    def initialize(message, text)
      @message = message
      @text = text
    end

    def to_s
      "#{@message}\nText: #{@text}"
    end
  end
end
