# frozen_string_literal: true

require "mistral-ai"

RSpec.describe Langchain::LLM::MistralAI do
  let(:subject) { described_class.new(api_key: "123") }

  describe "#chat" do
    it "calls the client with the requested parameters" do
      mock_client = instance_double(Mistral::Controllers::Client)
      allow(Mistral).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:chat_completions)
      params = {
        messages: [{role: "user", content: "Beep"}, {role: "assistant", content: "Boop"}, {role: "user", content: "bop"}],
        temperature: 1,
        max_tokens: 50,
        safe_prompt: "pow",
        seed: 5
      }

      subject.chat(params)

      expect(mock_client).to have_received(:chat_completions).with(
        messages: params[:messages],
        model: subject.defaults[:chat_completion_model_name],
        temperature: 1,
        max_tokens: 50,
        safe_prompt: "pow",
        random_seed: 5
      )
    end
  end

  xdescribe "#embed"
end
