# frozen_string_literal: true

require "mistral-ai"

RSpec.describe Langchain::LLM::MistralAI do
  let(:subject) { described_class.new(api_key: "123") }

  let(:mock_client) { instance_double(Mistral::Controllers::Client) }

  before do
    allow(Mistral).to receive(:new).and_return(mock_client)
  end

  describe "#initialize" do
    context "when default_options are passed" do
      let(:default_options) { {response_format: {type: "json_object"}} }

      subject { described_class.new(api_key: "123", default_options: default_options) }

      it "sets the defaults options" do
        expect(subject.defaults[:response_format]).to eq(type: "json_object")
      end

      it "get passed to consecutive chat() call" do
        allow(mock_client).to receive(:chat_completions)
        subject.chat(messages: [{role: "user", content: "Hello json!"}])
        expect(subject.client).to have_received(:chat_completions).with(hash_including({response_format: {type: "json_object"}}))
      end
    end
  end

  describe "#chat" do
    before do
      allow(mock_client).to receive(:chat_completions)
    end

    it "calls the client with the requested parameters" do
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
