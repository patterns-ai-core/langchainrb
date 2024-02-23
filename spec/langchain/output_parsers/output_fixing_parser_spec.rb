# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe Langchain::OutputParsers::OutputFixingParser do
  let(:llm) { Langchain::LLM::OpenAI.new(api_key: "123") }
  let(:wrapped_parser) { Langchain::OutputParsers::StructuredOutputParser.from_json_schema(schema_example) }
  let(:prompt) { Langchain::Prompt::PromptTemplate.new(template: "Tell me a {adjective} joke.", input_variables: ["adjective"]) }
  let(:fix_parser) {described_class.from_llm(llm: llm, parser: wrapped_parser, prompt: prompt) }

  describe "#initialize" do
    it "creates a new instance from an llm, parser, and prompt" do
      expect(
        described_class.new(
          llm: llm,
          parser: wrapped_parser,
          prompt: prompt
        )
      ).to be_a(Langchain::OutputParsers::OutputFixingParser)
    end

    it "fails if llm input in incorrect" do
      expect {
        described_class.new(
          llm: "not an llm",
          parser: wrapped_parser,
          prompt: prompt
        )
      }.to raise_error(ArgumentError, /must be an instance of Langchain::LLM/)
    end

    it "fails if parser is not an output parser" do
      expect {
        described_class.new(
          llm: llm,
          parser: "not a parser",
          prompt: prompt
        )
      }.to raise_error(ArgumentError, /must be an instance of Langchain::OutputParsers/)
    end

    it "fails if prompt is incorrect" do
      expect {
        described_class.new(
          llm: llm,
          parser: wrapped_parser,
          prompt: "not a prompt object"
        )
      }.to raise_error(ArgumentError, /must be an instance of Langchain::Prompt::PromptTemplate/)
    end
  end

  describe "#to_h" do
    it "returns Hash representation of output fixing parser" do
      expect(fix_parser.to_h).to eq({
        _type: "OutputFixingParser",
        parser: wrapped_parser.to_h,
        prompt: prompt.to_h
      })
    end
  end

  describe "#get_format_instructions" do
    it "returns the format_instructions from the wrapped parser" do
      expect(fix_parser.get_format_instructions).to eq(wrapped_parser.get_format_instructions)
    end
  end

  describe "#parse" do
    subject { fix_parser.parse(json_text_response) }

    it "calls parse on the wrapped parser" do
      allow(wrapped_parser).to receive(:parse).with(json_text_response)
      subject
      expect(wrapped_parser).to have_received(:parse).with(json_text_response)
    end

    it "creates a new completion if the wrapped parser raises an exception" do
      allow(llm).to receive(:chat).and_return(double(completion: json_text_response))
      fix_parser.parse(invalid_schema_json_text_response)
      expect(llm).to have_received(:chat).with(hash_including(:messages))
    end

    context "when the llm does not implement #chat" do
      let(:llm) { Langchain::LLM::Anthropic.new(api_key: "123") }

      it "raises NotImplementedError" do
        expect { fix_parser.parse(invalid_schema_json_text_response) }.to raise_error(NotImplementedError)
      end
    end
  end

  describe ".from_llm" do
    it "creates a new instance from an existing LLM (and parser)" do
      parser = described_class.from_llm(llm: llm, parser: wrapped_parser, prompt: prompt)
      expect(parser).to be_a(Langchain::OutputParsers::OutputFixingParser)
    end

    context "when the fix prompt is not included" do
      it "creates a new instance with a predefined fix prompt" do
        parser = described_class.from_llm(llm: llm, parser: wrapped_parser)
        expect(parser).to be_a(Langchain::OutputParsers::OutputFixingParser)
        expect(parser.prompt.format).to eq(described_class.send(:naive_fix_prompt).format)
      end
    end
  end
end
