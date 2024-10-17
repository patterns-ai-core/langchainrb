# frozen_string_literal: true

require "cohere"

RSpec.describe Langchain::LLM::Cohere do
  let(:subject) { described_class.new(api_key: "123") }

  describe "#initialize" do
    context "when default_options are passed" do
      let(:default_options) { {response_format: {type: "json_object"}} }

      subject { described_class.new(api_key: "123", default_options: default_options) }

      it "sets the defaults options" do
        expect(subject.defaults[:response_format]).to eq(type: "json_object")
      end

      it "get passed to consecutive chat() call" do
        subject
        expect(subject.client).to receive(:chat).with(hash_including({response_format: {type: "json_object"}})).and_return({})
        subject.chat(messages: [{role: "user", message: "Hello json!"}])
      end
    end
  end

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
          default_options: {complete_model: "base-light"}
        )
      }

      # TODO: Fix this test
      # The model specified above ({complete_model: "base-light"}) is not being used when the call is made.
      xit "passes correct options to the completions method" do
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

  describe "#chat" do
    let(:fixture) { File.read("spec/fixtures/llm/cohere/chat.json") }
    let(:response) { JSON.parse(fixture) }

    before do
      allow(subject.client).to receive(:chat)
        .with(
          model: "command-r-plus",
          temperature: 0.0,
          preamble: "You are a cheerful happy chatbot!",
          chat_history: [],
          message: "How are you?"
        )
        .and_return(response)
    end

    it "returns a response" do
      expect(
        subject.chat(
          system: "You are a cheerful happy chatbot!",
          messages: [{role: "user", message: "How are you?"}]
        )
      ).to be_a(Langchain::LLM::CohereResponse)
    end
  end

  describe "#default_dimensions" do
    it "returns the default dimensions" do
      expect(subject.default_dimensions).to eq(1024)
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
