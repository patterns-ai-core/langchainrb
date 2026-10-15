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
        subject.chat(messages: [{role: "user", content: "Hello json!"}])
      end
    end
  end

  describe "#embed" do
    let(:v2_response) do
      {
        "id" => "a86a12ca-7ce5-4433-b68a-4d8454b22de7",
        "texts" => ["Hello World"],
        "embeddings" => {"float" => [[-1.5693359, -0.9458008, 1.9355469]]}
      }
    end

    it "calls the v2 Embed API with an input_type and float embeddings" do
      expect(subject.client).to receive(:embed).with(
        texts: ["Hello World"],
        model: "embed-english-v3.0",
        input_type: "search_document",
        embedding_types: ["float"]
      ).and_return(v2_response)

      expect(subject.embed(text: "Hello World").embedding).to eq([-1.5693359, -0.9458008, 1.9355469])
    end

    it "passes a custom input_type" do
      expect(subject.client).to receive(:embed).with(hash_including(input_type: "search_query")).and_return(v2_response)

      subject.embed(text: "Hello World", input_type: "search_query")
    end
  end

  describe "#chat" do
    let(:fixture) { File.read("spec/fixtures/llm/cohere/chat_v2.json") }
    let(:response) { JSON.parse(fixture) }
    let(:expected_messages) do
      [
        {role: "system", content: "You are a cheerful happy chatbot!"},
        {role: "user", content: "Hi"},
        {role: "assistant", content: "Hello!"},
        {role: "user", content: "How are you?"}
      ]
    end

    it "sends the messages and the system prompt to the v2 Chat API" do
      expect(subject.client).to receive(:chat)
        .with(model: "command-r-plus", temperature: 0.0, messages: expected_messages)
        .and_return(response)

      result = subject.chat(
        system: "You are a cheerful happy chatbot!",
        messages: [
          {role: "user", content: "Hi"},
          {role: "assistant", content: "Hello!"},
          {role: "user", content: "How are you?"}
        ]
      )

      expect(result).to be_a(Langchain::LLM::Response::CohereResponse)
      expect(result.chat_completion).to eq("I'm doing well, thanks for asking! How can I help you today?")
    end

    it "converts v1 chat_history entries to v2 messages" do
      expect(subject.client).to receive(:chat)
        .with(model: "command-r-plus", temperature: 0.0, messages: expected_messages)
        .and_return(response)

      subject.chat(
        system: "You are a cheerful happy chatbot!",
        messages: [
          {role: "USER", message: "Hi"},
          {role: "CHATBOT", message: "Hello!"},
          {role: "USER", message: "How are you?"}
        ]
      )
    end

    it "maps stop, top_k and top_p to the Cohere parameter names" do
      expect(subject.client).to receive(:chat)
        .with(hash_including(stop_sequences: ["END"], k: 5, p: 0.9))
        .and_return(response)

      subject.chat(messages: [{role: "user", content: "Hi"}], stop: ["END"], top_k: 5, top_p: 0.9)
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
