# frozen_string_literal: true

module LangChain::OutputParsers
  # = Output Fixing Parser
  #
  class OutputFixingParser < Base
    attr_reader :llm, :parser, :prompt

    # Initializes a new instance of the class.
    #
    # @param llm [LangChain::LLM] The LLM used in the fixing process
    # @param parser [LangChain::OutputParsers] The parser originally used which resulted in parsing error
    # @param prompt [LangChain::Prompt::PromptTemplate]
    def initialize(llm:, parser:, prompt:)
      raise ArgumentError.new("llm must be an instance of LangChain::LLM got: #{llm.class}") unless llm.is_a?(LangChain::LLM::Base)
      raise ArgumentError.new("parser must be an instance of LangChain::OutputParsers got #{parser.class}") unless parser.is_a?(LangChain::OutputParsers::Base)
      raise ArgumentError.new("prompt must be an instance of LangChain::Prompt::PromptTemplate got #{prompt.class}") unless prompt.is_a?(LangChain::Prompt::PromptTemplate)
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
    # @param llm [LangChain::LLM] The LLM used in the fixing process
    # @param parser [LangChain::OutputParsers] The parser originally used which resulted in parsing error
    # @param prompt [LangChain::Prompt::PromptTemplate]
    #
    # @return [Object] A new instance of the class
    def self.from_llm(llm:, parser:, prompt: nil)
      new(llm: llm, parser: parser, prompt: prompt || naive_fix_prompt)
    end

    private

    private_class_method def self.naive_fix_prompt
      LangChain::Prompt.load_from_path(
        file_path: LangChain.root.join("langchain/output_parsers/prompts/naive_fix_prompt.yaml")
      )
    end
  end
end
