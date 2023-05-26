# frozen_string_literal: true

require "google_palm_api"

RSpec.describe LLM::GooglePalm do
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
      expect(subject.complete(prompt: "Hello world")).to eq("A man walks into a library and asks for books about paranoia. The librarian whispers, \"They're right behind you!\"")
    end
  end

  describe "#chat" do
    let(:completion) { "Hey there! How are you?" }
    let(:fixture) { File.read("spec/fixtures/llm/google_palm/chat.json") }

    before do
      allow(subject.client).to receive(:generate_chat_message).and_return(
        JSON.parse(fixture)
      )
    end

    it "returns a message" do
      expect(subject.chat(prompt: "Hey there! How are you?")).to eq("I am doing well, thank you for asking! I am excited to be able to help people with their tasks and to learn more about the world. How are you doing today?")
    end
  end
end
