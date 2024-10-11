# frozen_string_literal: true

RSpec.describe Langchain::Assistant::LLM::Adapter do
  let(:llm) { Langchain::LLM::OpenAI.new(api_key: "123") }

  it "initialize a new OpenAI adapter" do
    expect(described_class.build(llm)).to be_a(Langchain::Assistant::LLM::Adapters::OpenAI)
  end
end
