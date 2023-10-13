# frozen_string_literal: true

require "cohere"

RSpec.describe Langchain::LLM::Cohere do
  let(:subject) { described_class.new(api_key: "123") }

  describe "#embed" do
    before do
      allow(subject.client).to receive(:embed).and_return(
        {
          "id" => "a86a12ca-7ce5-4433-b68a-4d8454b22de7",
          "texts" => ["Hello World"],
          "embeddings" => [[-1.5693359, -0.9458008, 1.9355469]]
        }
      )
    end

    it "returns an embedding" do
      expect(subject.embed(text: "Hello World").embedding).to eq([-1.5693359, -0.9458008, 1.9355469])
    end
  end

  describe "#complete" do
    before do
      allow(subject.client).to receive(:generate).and_return(
        {
          "id" => "812c650e-a0d0-4502-a084-45b0d32fcb9c",
          "generations" => [
            {
              "id" => "8b79fd4f-7c72-4e1d-97a1-3dbe49206db2",
              "text" => "\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning"
            }
          ],
          "prompt" => "What is the meaining of life?",
          "meta" => {"api_version" => {"version" => "1"}}
        }
      )

      allow(subject.client).to receive(:tokenize).and_return(
        {
          "tokens" => [
            33555,
            1114,
            34
          ],
          "token_strings" => [
            "hello",
            " world",
            "!"
          ],
          "meta" => {
            "api_version" => {
              "version" => "1"
            }
          }
        }
      )
    end

    it "returns a completion" do
      expect(subject.complete(prompt: "Hello World").completion).to eq("\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning")
    end

    context "with custom default_options" do
      let(:subject) {
        described_class.new(
          api_key: "123",
          default_options: {completion_model_name: "base-light"}
        )
      }

      it "passes correct options to the completions method" do
        expect(subject.client).to receive(:generate).with(
          {
            max_tokens: 2045,
            model: "base-light",
            prompt: "Hello World",
            temperature: 0.0,
            truncate: "START"
          }
        )
        subject.complete(prompt: "Hello World")
      end
    end
  end

  describe "#default_dimension" do
    it "returns the default dimension" do
      expect(subject.default_dimension).to eq(1024)
    end
  end

  describe "#summarize" do
    let(:text) { "Text to summarize" }

    before do
      allow(subject.client).to receive(:summarize).and_return(
        {
          "id" => "123",
          "summary" => "Summary",
          "meta" => {"api_version" => {"version" => "1"}}
        }
      )
    end

    it "returns a summary" do
      expect(subject.summarize(text: text)).to eq("Summary")
    end
  end
end
