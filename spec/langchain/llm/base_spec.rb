# frozen_string_literal: true

require "cohere"

RSpec.describe Langchain::LLM::Base do
  let(:subject) { described_class.new }

  describe "#chat" do
    it "raises an error" do
      expect { subject.chat }.to raise_error(NotImplementedError)
    end
  end

  describe "#complete" do
    it "raises an error" do
      expect { subject.complete }.to raise_error(NotImplementedError)
    end
  end

  describe "#embed" do
    it "raises an error" do
      expect { subject.embed }.to raise_error(NotImplementedError)
    end
  end

  describe "#validate_llm!" do
    it "raises an error" do
      expect {
        described_class.validate_llm!(llm: :openai)
      }.not_to raise_error
    end

    it "does not raise an error" do
      expect {
        described_class.validate_llm!(llm: :anthropic)
      }.to raise_error(ArgumentError)
    end
  end
end
