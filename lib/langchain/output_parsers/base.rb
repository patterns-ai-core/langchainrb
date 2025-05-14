# frozen_string_literal: true

module Langchain::OutputParsers
  # Structured output parsers from the LLM.
  #
  # @abstract
  class Base
    # Parse the output of an LLM call.
    #
    # @param text - LLM output to parse.
    #
    # @return [Object] Parsed output.
    def parse(text:)
      raise NotImplementedError
    end

    # Return a string describing the format of the output.
    #
    # @return [String] Format instructions.
    #
    # @example returns the format instructions
    # ```json
    # {
    #  "foo": "bar"
    # }
    # ```
    def get_format_instructions
      raise NotImplementedError
    end
  end
end
