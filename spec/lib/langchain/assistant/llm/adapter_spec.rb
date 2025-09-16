# frozen_string_literal: true

RSpec.describe LangChain::Assistant::LLM::Adapter do
  let(:llm) { LangChain::LLM::OpenAI.new(api_key: "123") }

  it "initialize a new OpenAI adapter" do
    expect(described_class.build(llm)).to be_a(LangChain::Assistant::LLM::Adapters::OpenAI)
  end
end
