# frozen_string_literal: true

RSpec.describe Langchain::LLM::OpenAI do
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
        # openai-ruby sets global configuration options here: https://github.com/alexrudall/ruby-openai/blob/main/lib/openai/client.rb
        expect(OpenAI.configuration.uri_base).to eq("http://localhost:1234")
      end
    end
  end

  describe "#embed" do
    let(:response) do
      {
        "object" => "list",
        "data" => [
          {
            "object" => "embedding",
            "index" => 0,
            "embedding" => [
              -0.007097351,
              0.0035200312,
              -0.0069700438
            ]
          }
        ]
      }
    end

    before do
      allow(subject.client).to receive(:embeddings).with(parameters).and_return(response)
    end

    context "with default parameters" do
      let(:parameters) do
        {parameters: {input: "Hello World", model: "text-embedding-ada-002"}}
      end
      it "returns an embedding" do
        expect(subject.embed(text: "Hello World")).to eq([-0.007097351, 0.0035200312, -0.0069700438])
      end
    end

    context "with text and  parameters" do
      let(:parameters) do
        {parameters: {input: "Hello World", model: "text-embedding-ada-001", user: "id"}}
      end
      it "returns an embedding" do
        expect(subject.embed(text: "Hello World", model: "text-embedding-ada-001", user: "id")).to eq([-0.007097351, 0.0035200312, -0.0069700438])
      end
    end
  end

  describe "#complete" do
    let(:response) do
      {
        "id" => "cmpl-7BZg4cP5xzga4IyLI6u97WMepAJj2",
        "object" => "text_completion",
        "created" => 1682993108,
        "model" => "text-davinci-003",
        "choices" => [
          {
            "text" => "\n\nThe meaning of life is subjective and can vary from person to person.",
            "index" => 0,
            "logprobs" => nil,
            "finish_reason" => "length"
          }
        ],
        "usage" => {
          "prompt_tokens" => 7,
          "completion_tokens" => 16,
          "total_tokens" => 23
        }
      }
    end

    before do
      allow(subject.client).to receive(:completions).with(parameters).and_return(response)
    end

    context "with default parameters" do
      let(:parameters) do
        {parameters: {model: "text-davinci-003", prompt: "Hello World", temperature: 0.0}}
      end

      it "returns a completion" do
        expect(subject.complete(prompt: "Hello World")).to eq("\n\nThe meaning of life is subjective and can vary from person to person.")
      end
    end

    context "with prompt and parameters" do
      let(:parameters) do
        {parameters: {model: "text-curie-001", prompt: "Hello World", temperature: 1.0}}
      end

      it "returns a completion" do
        expect(subject.complete(prompt: "Hello World", model: "text-curie-001", temperature: 1.0)).to eq("\n\nThe meaning of life is subjective and can vary from person to person.")
      end
    end
  end

  describe "#default_dimension" do
    it "returns the default dimension" do
      expect(subject.default_dimension).to eq(1536)
    end
  end

  describe "#chat" do
    let(:response) do
      {
        "id" => "chatcmpl-7Hcl1sXOtsaUBKJGGhNujEIwhauaD",
        "object" => "chat.completion",
        "created" => 1684434915,
        "model" => "gpt-3.5-turbo-0301",
        "usage" => {
          "prompt_tokens" => 14,
          "completion_tokens" => 25,
          "total_tokens" => 39
        },
        "choices" => [
          {
            "message" => {
              "role" => "assistant",
              "content" => "As an AI language model, I don't have feelings, but I'm functioning well. How can I assist you today?"
            },
            "finish_reason" => "stop",
            "index" => 0
          }
        ]
      }
    end

    before do
      allow(subject.client).to receive(:chat).with(parameters).and_return(response)
    end

    context "with default parameters" do
      let(:parameters) do
        {parameters: {messages: [{content: "Hello! How are you?", role: "user"}], model: "gpt-3.5-turbo", temperature: 0.0}}
      end

      it "returns a chat message" do
        expect(subject.chat(prompt: "Hello! How are you?")).to eq("As an AI language model, I don't have feelings, but I'm functioning well. How can I assist you today?")
      end
    end

    context "with prompt and parameters" do
      let(:parameters) do
        {parameters: {messages: [{content: "Hello! How are you?", role: "user"}], model: "gpt-3.5-turbo-0301", temperature: 0.75}}
      end

      it "returns a chat message" do
        expect(subject.chat(prompt: "Hello! How are you?", model: "gpt-3.5-turbo-0301", temperature: 0.75)).to eq("As an AI language model, I don't have feelings, but I'm functioning well. How can I assist you today?")
      end
    end
  end

  describe "#summarize" do
    let(:text) { "Text to summarize" }

    before do
      allow(subject).to receive(:complete).and_return("Summary")
    end

    it "returns a summary" do
      expect(subject.summarize(text: text)).to eq("Summary")
    end
  end
end
