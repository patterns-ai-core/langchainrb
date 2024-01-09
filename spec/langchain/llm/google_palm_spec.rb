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

    it "returns valid llm response object" do
      response = subject.embed(text: "Hello world")

      expect(response).to be_a(Langchain::LLM::GooglePalmResponse)
      expect(response.model).to eq("embedding-gecko-001")
      expect(response.embedding).to eq(embedding)
      # expect(response.prompt_tokens).to eq(nil)
    end

    it "returns an embedding" do
      response = subject.embed(text: "Hello world")

      expect(response.embedding).to eq(embedding)
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

    it "returns valid llm response object" do
      response = subject.complete(prompt: completion)

      expect(response).to be_a(Langchain::LLM::GooglePalmResponse)
      expect(response.model).to eq("text-bison-001")
      expect(response.completion).to eq("A man walks into a library and asks for books about paranoia. The librarian whispers, \"They're right behind you!\"")
      # expect(response.prompt_tokens).to eq(nil)
    end

    it "returns a completion" do
      response = subject.complete(prompt: completion)

      expect(response.completion).to eq("A man walks into a library and asks for books about paranoia. The librarian whispers, \"They're right behind you!\"")
    end

    context "with custom default_options" do
      let(:subject) {
        described_class.new(
          api_key: "123",
          default_options: {completion_model_name: "text-bison-foo"}
        )
      }

      it "passes correct options to the completions method" do
        expect(subject.client).to receive(:generate_text).with(
          {
            model: "text-bison-foo",
            prompt: "Hello World",
            temperature: 0.0
          }
        ).and_return(response)
        subject.complete(prompt: "Hello World")
      end
    end
  end

  describe "#chat" do
    let(:completion) { "Hey there! How are you?" }

    context "when prompt is too long" do
      let(:fixture) { File.read("spec/fixtures/llm/google_palm/chat.json") }

      before do
        allow(subject.client).to receive(:count_message_tokens).and_return(
          {"tokenCount" => 10000}
        )

        allow(subject.client).to receive(:generate_chat_message).and_return(
          JSON.parse(fixture)
        )
      end

      it "returns a message" do
        expect {
          subject.chat(prompt: completion)
        }.to raise_error(Langchain::Utils::TokenLength::TokenLimitExceeded, "This model's maximum context length is 4000 tokens, but the given text is 10000 tokens long.")
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

      it "returns valid llm response object" do
        response = subject.chat(prompt: completion)

        expect(response).to be_a(Langchain::LLM::GooglePalmResponse)
        expect(response.model).to eq("chat-bison-001")
        expect(response.chat_completion).to eq("I am doing well, thank you for asking! I am excited to be able to help people with their tasks and to learn more about the world. How are you doing today?")
        # TODO: Fix this
        # expect(response.prompt_tokens).to eq(nil)
      end

      it "returns a message" do
        response = subject.chat(prompt: completion)

        expect(response.chat_completion).to eq("I am doing well, thank you for asking! I am excited to be able to help people with their tasks and to learn more about the world. How are you doing today?")
      end

      context "with custom default_options" do
        let(:subject) {
          described_class.new(
            api_key: "123",
            default_options: {chat_completion_model_name: "chat-bison-foo"}
          )
        }

        it "passes correct options to the completions method" do
          expect(subject.client).to receive(:generate_chat_message).with(
            {
              model: "chat-bison-foo",
              context: "",
              examples: [],
              messages: [{author: "user", content: "Hey there! How are you?"}],
              temperature: 0.0
            }
          )
          subject.chat(prompt: completion)
        end
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
        response = subject.chat(messages: [
          {role: "user", content: completion},
          {role: "assistant", content: "I am doing well, thank you for asking! I am excited to be able to help people with their tasks and to learn more about the world. How are you doing today?"},
          {role: "user", content: "I'm doing great. What are you up to?"}
        ])

        expect(response.chat_completion).to eq("I am currently working on a project to help people with their tasks. I am also learning more about the world and how to interact with people. I am excited to be able to help people and to learn more about the world.\r\n\r\nWhat are you up to today?")
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
