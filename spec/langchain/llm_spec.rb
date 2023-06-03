# frozen_string_literal: true

require "cohere"

RSpec.describe Langchain::LLM do
  let(:subject) { described_class }
  let(:api_key) { "123" }

  describe ".build" do
    it "raises an error for invalid llm names" do
      expect {
        subject.build(:openai, api_key: api_key)
      }.not_to raise_error
    end

    it "does not raise an error for valid llm names" do
      expect {
        subject.build(:anthropic, api_key: api_key)
      }.to raise_error(ArgumentError)
    end
  end
end
