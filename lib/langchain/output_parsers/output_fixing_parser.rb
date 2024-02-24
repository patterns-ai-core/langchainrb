# frozen_string_literal: true

module Langchain::OutputParsers
  # = Output Fixing Parser
  #
  class OutputFixingParser < Base
    attr_reader :llm, :parser, :prompt

    # Initializes a new instance of the class.
    #
    # @param llm [Langchain::LLM] The LLM used in the fixing process
    # @param parser [Langchain::OutputParsers] The parser originally used which resulted in parsing error
    # @param prompt [Langchain::Prompt::PromptTemplate]
    def initialize(llm:, parser:, prompt:)
      raise ArgumentError.new("llm must be an instance of Langchain::LLM got: #{llm.class}") unless llm.is_a?(Langchain::LLM::Base)
      raise ArgumentError.new("parser must be an instance of Langchain::OutputParsers got #{parser.class}") unless parser.is_a?(Langchain::OutputParsers::Base)
      raise ArgumentError.new("prompt must be an instance of Langchain::Prompt::PromptTemplate got #{prompt.class}") unless prompt.is_a?(Langchain::Prompt::PromptTemplate)
      @llm = llm
      @parser = parser
      @prompt = prompt
    end

    def to_h
      {
        _type: "OutputFixingParser",
        parser: parser.to_h,
        prompt: prompt.to_h
      }
    end

    # calls get_format_instructions on the @parser
    #
    # @return [String] Instructions for how the output of a language model should be formatted
    # according to the @schema.
    def get_format_instructions
      parser.get_format_instructions
    end

    # Parse the output of an LLM call, if fails with OutputParserException
    # then call the LLM with a fix prompt in an attempt to get the correctly
    # formatted response
    #
    # @param completion [String] Text output from the LLM call
    #
    # @return [Object] object that is succesfully parsed by @parser.parse
    def parse(completion)
      parser.parse(completion)
    rescue OutputParserException => e
      new_completion = llm.chat(
        messages: [{role: "user",
                    content: prompt.format(
                      instructions: parser.get_format_instructions,
                      completion: completion,
                      error: e
                    )}]
      ).completion
      parser.parse(new_completion)
    end

    # Creates a new instance of the class using the given JSON::Schema.
    #
    # @param llm [Langchain::LLM] The LLM used in the fixing process
    # @param parser [Langchain::OutputParsers] The parser originally used which resulted in parsing error
    # @param prompt [Langchain::Prompt::PromptTemplate]
    #
    # @return [Object] A new instance of the class
    def self.from_llm(llm:, parser:, prompt: nil)
      new(llm: llm, parser: parser, prompt: prompt || naive_fix_prompt)
    end

    private

    private_class_method def self.naive_fix_prompt
      Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/output_parsers/prompts/naive_fix_prompt.yaml")
      )
    end
  end
end
