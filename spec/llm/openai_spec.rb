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
end
