# frozen_string_literal: true

RSpec.describe Langchain::LLM::AnthropicResponse do
  let(:raw_chat_completions_response) {
    JSON.parse File.read("spec/fixtures/llm/anthropic/chat.json")
  }

  describe "#chat_completion" do
    it "return chat_completion" do
      subject = described_class.new(raw_chat_completions_response)
      expect(subject.chat_completion).to eq("The sky doesn't have a defined height or upper limit.")
    end
  end
end
