# frozen_string_literal: true

RSpec.describe LLM::OpenAI do
  let(:subject) { described_class.new(api_key: "123") }

  describe "#embed" do
    before do
      allow_any_instance_of(OpenAI::Client).to receive(:embeddings).and_return({
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
      })
    end

    it "returns an embedding" do
      expect(subject.embed(text: "Hello World")).to eq([-0.007097351, 0.0035200312, -0.0069700438])
    end
  end

  describe "#complete" do
    before do
      allow_any_instance_of(OpenAI::Client).to receive(:completions).and_return(
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
      )
    end

    it "returns a completion" do
      expect(subject.complete(prompt: "Hello World")).to eq("\n\nThe meaning of life is subjective and can vary from person to person.")
    end
  end

  describe "#default_dimension" do
    it "returns the default dimension" do
      expect(subject.default_dimension).to eq(1536)
    end
  end

  describe "#chat" do
    before do
      allow_any_instance_of(OpenAI::Client).to receive(:chat).and_return(
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
      )
    end

    it "returns a chat message" do
      expect(subject.chat(prompt: "Hello! How are you?")).to eq("As an AI language model, I don't have feelings, but I'm functioning well. How can I assist you today?")
    end
  end
end
