# frozen_string_literal: true

RSpec.describe Langchain::LLM::Response::CohereResponse do
  let(:raw_chat_completions_response) {
    JSON.parse File.read("spec/fixtures/llm/cohere/chat.json")
  }

  subject { described_class.new(raw_chat_completions_response) }

  describe "#chat_completion" do
    it "returns chat_completion" do
      expect(subject.chat_completion).to eq("I am an AI chatbot and do not possess emotions or feelings, so the concept of \"being\" does not apply to me in the traditional sense. However, I am functioning properly and ready to assist you with any queries or tasks you may have. How can I help you today?")
    end

    it "returns role" do
      expect(subject.role).to eq("CHATBOT")
    end
  end
end
