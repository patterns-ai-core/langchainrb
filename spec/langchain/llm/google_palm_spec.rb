# frozen_string_literal: true

require "google_palm_api"

RSpec.describe Langchain::LLM::GooglePalm do
  let(:subject) { described_class.new(api_key: "123") }

  describe "#embed" do
    let(:embedding) { [-0.0039720302, 0.008623508, 0.027801897] }

    before do
      allow(subject.client).to receive(:embed).and_return(
        {"embedding" => {"value" => embedding}}
      )
    end

    it "returns an embedding" do
      expect(subject.embed(text: "Hello world")).to eq(embedding)
    end
  end

  describe "#complete" do
    let(:completion) { "Tell me a harmless joke!" }
    let(:fixture) { File.read("spec/fixtures/llm/google_palm/complete.json") }
    let(:response) { JSON.parse(fixture) }

    before do
      allow(subject.client).to receive(:generate_text).and_return(
        response
      )
    end

    it "returns a completion" do
      expect(subject.complete(prompt: completion)).to eq("A man walks into a library and asks for books about paranoia. The librarian whispers, \"They're right behind you!\"")
    end
  end

  describe "#chat" do
    let(:completion) { "Hey there! How are you?" }

    context "when prompt is too long" do
      let(:fixture) { File.read("spec/fixtures/llm/google_palm/chat.json") }

      before do
        allow(subject.client).to receive(:count_message_tokens).and_return(
          {"tokenCount" => 4000}
        )

        allow(subject.client).to receive(:generate_chat_message).and_return(
          JSON.parse(fixture)
        )
      end

      it "returns a message" do
        expect {
          subject.chat(prompt: completion)
        }.to raise_error(Langchain::Utils::TokenLength::TokenLimitExceeded, "This model's maximum context length is 4000 tokens, but the given text is 4000 tokens long.")
      end
    end

    context "when prompt is passed in" do
      let(:fixture) { File.read("spec/fixtures/llm/google_palm/chat.json") }

      before do
        allow(subject.client).to receive(:count_message_tokens).and_return(
          {"tokenCount" => 27}
        )

        allow(subject.client).to receive(:generate_chat_message).and_return(
          JSON.parse(fixture)
        )
      end

      it "returns a message" do
        expect(subject.chat(prompt: completion)).to eq("I am doing well, thank you for asking! I am excited to be able to help people with their tasks and to learn more about the world. How are you doing today?")
      end
    end

    context "when messages are passed in" do
      let(:fixture) { File.read("spec/fixtures/llm/google_palm/chat_2.json") }

      before do
        allow(subject.client).to receive(:count_message_tokens).and_return(
          {"tokenCount" => 27}
        )

        allow(subject.client).to receive(:count_message_tokens).and_return(
          {"tokenCount" => 56}
        )

        allow(subject.client).to receive(:count_message_tokens).and_return(
          {"tokenCount" => 32}
        )

        allow(subject.client).to receive(:generate_chat_message).and_return(
          JSON.parse(fixture)
        )
      end

      it "returns a message" do
        expect(
          subject.chat(messages: [
            {author: "0", content: completion},
            {author: "1", content: "I am doing well, thank you for asking! I am excited to be able to help people with their tasks and to learn more about the world. How are you doing today?"},
            {author: "0", content: "I'm doing great. What are you up to?"}
          ])
        ).to eq("I am currently working on a project to help people with their tasks. I am also learning more about the world and how to interact with people. I am excited to be able to help people and to learn more about the world.\r\n\r\nWhat are you up to today?")
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
