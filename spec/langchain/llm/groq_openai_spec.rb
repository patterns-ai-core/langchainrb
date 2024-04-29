# frozen_string_literal: true

RSpec.describe Langchain::LLM::GroqOpenAi do
  let(:subject) { described_class.new(api_key: "123") }

  describe "#initialize" do
    context "when only required options are passed" do
      it "initializes the client without any errors" do
        expect { subject }.not_to raise_error
      end
    end

    context "when llm_options are passed" do
      let(:subject) { described_class.new(api_key: "123", llm_options: {uri_base: "http://localhost:1234"}) }

      it "initializes the client without any errors" do
        expect { subject }.not_to raise_error
      end

      it "passes correct options to the client" do
        result = subject
        expect(result.client.access_token).to eq("123")
        expect(result.client.uri_base).to eq("http://localhost:1234")
      end
    end
  end

  describe "#chat" do
    let(:subject) { described_class.new(api_key: "123", default_options: {chat_completion_model_name: "mixtral-8x7b-32768"}) }

    let(:prompt) { "What is the meaning of life?" }
    let(:model) { "mixtral-8x7b-32768" } # Optional since default_options is set
    let(:temperature) { 0.0 }
    let(:n) { 1 }
    let(:history) { [content: prompt, role: "user"] }
    let(:parameters) { {parameters: {n: n, messages: history, model: model, temperature: temperature}} }
    let(:answer) { "As an AI language model, I don't have feelings, but I'm functioning well. How can I assist you today?" }
    # let(:answer_2) { "Alternative answer" }
    let(:choices) do
      [
        {
          "message" => {
            "role" => "assistant",
            "content" => answer
          },
          "finish_reason" => "stop",
          "index" => 0
        }
      ]
    end
    let(:response) do
      {
        "id" => "chatcmpl-7Hcl1sXOtsaUBKJGGhNujEIwhauaD",
        "object" => "chat.completion",
        "created" => 1684434915,
        "model" => model,
        "usage" => {
          "prompt_tokens" => 14,
          "completion_tokens" => 25,
          "total_tokens" => 39
        },
        "choices" => choices
      }
    end

    before do
      allow(subject.client).to receive(:chat).with(parameters).and_return(response)
    end

    it "returns valid llm response object" do
      response = subject.chat(messages: [{role: "user", content: "What is the meaning of life?"}])

      expect(response).to be_a(Langchain::LLM::OpenAIResponse)
      expect(response.model).to eq(model)
      expect(response.completions).to eq(choices)
      expect(response.chat_completion).to eq(answer)
      expect(response.prompt_tokens).to eq(14)
      expect(response.completion_tokens).to eq(25)
      expect(response.total_tokens).to eq(39)
    end
  end
end
