# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe Langchain::OutputParsers::OutputFixingParser do
  let!(:llm_example) do
    Langchain::LLM::OpenAI.new(api_key: "123")
  end

  let!(:parser_example) do
    Langchain::OutputParsers::StructuredOutputParser.from_json_schema(schema_example)
  end

  let!(:prompt_template_example) do
    Langchain::Prompt::PromptTemplate.new(
      template: "Generate details of a fictional character.\n{format_instructions}\nCharacter description: {description}",
      input_variables: ["description", "format_instructions"]
    )
  end

  let!(:kwargs_example) do
    {
      llm: llm_example,
      parser: parser_example,
      prompt: prompt_template_example
    }
  end

  describe "#initialize" do
    it "creates a new instance" do
      expect(described_class.new(**kwargs_example)).to be_a(Langchain::OutputParsers::OutputFixingParser)
    end

    [
      {named: "llm", expect_class: "Langchain::LLM", llm: {}},
      {named: "parser", expect_class: "Langchain::OutputParsers", parser: {}},
      {named: "prompt", expect_class: "Langchain::Prompt::PromptTemplate", prompt: {}}
    ].each do |data|
      named = data[:named]
      expect_class = data[:expect_class]

      it "fails if input #{named} is not #{expect_class}" do
        kwargs = kwargs_example.merge(data.reject { |key| [:named, :expect_class].include?(key) })
        expect { described_class.new(**kwargs) }.to raise_error(ArgumentError, /#{expect_class}/)
      end
    end
  end

  describe "#to_h" do
    it "returns Hash representation of output fixing parser" do
      parser = described_class.new(**kwargs_example)
      expect(parser.to_h).to eq({
        _type: "OutputFixingParser",
        parser: kwargs_example[:parser].to_h,
        prompt: kwargs_example[:prompt].to_h
      })
    end
  end

  describe "#get_format_instructions" do
    it "returns format instructions for the input parser" do
      parser = described_class.new(**kwargs_example)
      expect(parser.get_format_instructions).to eq(kwargs_example[:parser].get_format_instructions)
    end
  end

  describe "#parse" do
    it "parses response text against the current @schema" do
      parser = described_class.from_json_schema(schema_example)
      expect(parser.parse(json_text_response)).to eq(json_response)
    end

    # it "fails to parse response text if its borked" do
    #   parser = described_class.from_json_schema(schema_example)
    #   expect {
    #     parser.parse("Sorry, I'm just a large language model blah blah..")
    #   }.to raise_error(Langchain::OutputParsers::OutputParserException)
    # end

    # it "fails to parse response text if the json does not conform to the schema" do
    #   parser = described_class.from_json_schema(schema_example)
    #   expect {
    #     parser.parse(
    #       <<~RESPONSE
    #         {
    #           "name": "Elon",
    #           "age": 51,
    #           "interests": []
    #         }
    #       RESPONSE
    #     )
    #   }.to raise_error(Langchain::OutputParsers::OutputParserException, /'#\/interests' did not contain a minimum number of items/)
    # end
  end

  describe ".from_llm" do
    it "creates a new instance from given llm, parser and prompt" do
      parser = described_class.from_llm(**kwargs_example)
      expect(parser).to be_a(Langchain::OutputParsers::OutputFixingParser)
      expect(parser.prompt.to_h).to eq(kwargs_example[:prompt].to_h)
    end

    it "defaults prompt to a naive_fix_prompt" do
      parser = described_class.from_llm(llm: kwargs_example[:llm], parser: kwargs_example[:parser])
      expect(parser).to be_a(Langchain::OutputParsers::OutputFixingParser)
      expect(parser.prompt.template).to eq(
        <<~INSTRUCTIONS.chomp
          Instructions:
          --------------
          {instructions}
          --------------
          Completion:
          --------------
          {completion}
          --------------
          
          Above, the Completion did not satisfy the constraints given in the Instructions.
          Error:
          --------------
          {error}
          --------------
          
          Please try again. Please only respond with an answer that satisfies the constraints laid out in the Instructions:
        INSTRUCTIONS
      )
    end

    [
      {named: "llm", expect_class: "Langchain::LLM", llm: nil},
      {named: "parser", expect_class: "Langchain::OutputParsers", parser: nil}
    ].each do |data|
      named = data[:named]
      expect_class = data[:expect_class]

      it "fails if input #{named} is not #{expect_class}" do
        kwargs = kwargs_example.merge(data.reject { |key| [:named, :expect_class].include?(key) })
        expect { described_class.from_llm(**kwargs) }.to raise_error(ArgumentError, /#{expect_class}/)
      end
    end
  end
end
