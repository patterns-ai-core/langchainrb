# frozen_string_literal: true

RSpec.describe Langchain::Conversation do
  let(:llm) { double("Langchain::LLM::OpenAI") }

  subject { described_class.new(llm: llm) }

  describe "#initialize" do
    let(:llm_response) do
      {
        "choices" => [
          {
            "message" => {"role" => "assistant", "content" => "I'm doing well. How about you?"}
          }
        ]
      }
    end

    before do
      allow(llm).to receive(:chat).and_return(Langchain::LLM::OpenAIResponse.new(llm_response))
    end

    context "with messages" do
      subject { described_class.new(llm: llm, messages: messages) }

      context "accepts and array of message objects" do
        let(:messages) do
          [Langchain::Conversation::Prompt.new("Hello"), Langchain::Conversation::Response.new("Hi")]
        end

        it "initializes the client without any errors" do
          expect(subject.messages.first).to be_a(Langchain::Conversation::Prompt)
          expect(subject.messages.first.to_s).to eq("Hello")

          expect(subject.messages.last).to be_a(Langchain::Conversation::Response)
          expect(subject.messages.last.to_s).to eq("Hi")
        end

        it "passes messages as hashes to llm" do
          expect(llm).to receive(:chat).with(context: nil, examples: [], messages: [
            {role: "user", content: "Hello"},
            {role: "assistant", content: "Hi"},
            {role: "user", content: "How are you?"}
          ])
          subject.message("How are you?")
        end
      end

      context "accepts and array of hashes" do
        let(:messages) do
          [{role: "user", content: "Hello"}, {role: "assistant", content: "Hi"}]
        end

        it "initializes the client without any errors" do
          expect(subject.messages.first).to be_a(Langchain::Conversation::Prompt)
          expect(subject.messages.first.to_s).to eq("Hello")

          expect(subject.messages.last).to be_a(Langchain::Conversation::Response)
          expect(subject.messages.last.to_s).to eq("Hi")
        end

        it "passes messages as hashes to llm" do
          expect(llm).to receive(:chat).with(context: nil, examples: [], messages: [
            {role: "user", content: "Hello"},
            {role: "assistant", content: "Hi"},
            {role: "user", content: "How are you?"}
          ])
          subject.message("How are you?")
        end
      end
    end
  end

  describe "#set_context" do
    let(:context) { "You are a chatbot" }

    it "sets the context" do
      subject.set_context(context)

      expect(subject.context).to eq(Langchain::Conversation::Context.new(context))
    end
  end

  describe "#add_examples" do
    context "with array of hashes" do
      let(:examples) do
        [
          {role: "user", content: "Hello"},
          {role: "assistant", content: "Hi"}
        ]
      end

      it "adds examples" do
        subject.add_examples(examples)

        expect(subject.examples.first).to be_a(Langchain::Conversation::Prompt)
        expect(subject.examples.first.to_s).to eq("Hello")
        expect(subject.examples.last).to be_a(Langchain::Conversation::Response)
        expect(subject.examples.last.to_s).to eq("Hi")
      end
    end

    context "with array of message objects" do
      let(:examples1) { [Langchain::Conversation::Prompt.new("Hello"), Langchain::Conversation::Response.new("Hi")] }
      let(:examples2) { [Langchain::Conversation::Prompt.new("How are you doing?"), Langchain::Conversation::Response.new("I'm doing well. How about you?")] }

      it "adds examples" do
        subject.add_examples(examples1)

        expect(subject.examples).to eq(examples1)

        subject.add_examples(examples2)
        expect(subject.examples).to eq(examples1 | examples2)
      end
    end
  end

  describe "#message" do
    let(:context) { "You are a chatbot" }
    let(:examples) { [Langchain::Conversation::Prompt.new("Hello"), Langchain::Conversation::Response.new("Hi")] }
    let(:prompt) { "How are you doing?" }
    let(:response) { Langchain::LLM::OpenAIResponse.new({"choices" => [{"message" => {"role" => "assistant", "content" => "I'm doing well. How about you?"}}]}) }

    context "with stream: true option and block passed in" do
      let(:block) { proc { |chunk| print(chunk) } }
      let(:conversation) { described_class.new(llm: llm, &block) }

      it "messages the model and yields the response" do
        expect(llm).to receive(:chat).with(
          context: nil,
          examples: [],
          messages: [{role: "user", content: prompt}],
          &block
        ).and_return(response)

        expect(conversation.message(prompt)).to eq(Langchain::Conversation::Response.new(response.chat_completion))
      end
    end

    context "with simple prompt" do
      it "messages the model and returns the response" do
        expect(llm).to receive(:chat).with(
          context: nil,
          examples: [],
          messages: [{role: "user", content: prompt}]
        ).and_return(response)

        expect(subject.message(prompt)).to eq(Langchain::Conversation::Response.new(response.chat_completion))
      end
    end

    context "with context" do
      before do
        subject.set_context(context)
      end

      it "messages the model and returns the response" do
        expect(llm).to receive(:chat).with(
          context: context,
          examples: [],
          messages: [{role: "user", content: prompt}]
        ).and_return(response)

        expect(subject.message(prompt)).to eq(Langchain::Conversation::Response.new(response.chat_completion))
      end
    end

    context "with context and examples" do
      before do
        subject.set_context(context)
        subject.add_examples(examples)
      end

      it "messages the model and returns the response" do
        expect(llm).to receive(:chat).with(
          context: context,
          examples: [
            {role: "user", content: "Hello"},
            {role: "assistant", content: "Hi"}
          ],
          messages: [{role: "user", content: prompt}]
        ).and_return(response)

        expect(subject.message(prompt)).to eq(Langchain::Conversation::Response.new(response.chat_completion))
      end
    end

    context "with options" do
      subject { described_class.new(llm: llm, temperature: 0.7) }

      it "messages the model with passed options" do
        expect(llm).to receive(:chat).with(
          context: nil,
          examples: [],
          messages: [{role: "user", content: prompt}],
          temperature: 0.7
        ).and_return(response)

        expect(subject.message(prompt)).to eq(Langchain::Conversation::Response.new(response.chat_completion))
      end
    end

    context "with length limit exceeded and truncate strategy" do
      let(:messages) { [] }

      subject { described_class.new(llm: llm, messages: messages) }

      before do
        allow(llm).to receive(:client).and_return(client)
        allow(client).to receive(:chat).and_return(response)
      end

      context "with OpenAI LLM" do
        let(:llm) { Langchain::LLM::OpenAI.new api_key: "TEST" }
        let(:client) { double("OpenAI::Client") }

        context "a single prompt that exceeds the token limit" do
          let(:prompt) { "Lorem " * 4096 }

          it "raises an error" do
            expect { subject.message(prompt) }.to raise_error(Langchain::Utils::TokenLength::TokenLimitExceeded)
          end
        end

        context "message history exceeds the token limit" do
          let(:prompt) { "Lorem " * 2048 }
          let(:response) do
            {"choices" => [{"message" => {"content" => "I'm doing well. How about you?"}}]}
          end
          let(:context) { "You are a chatbot" }
          let(:examples) { [Langchain::Conversation::Prompt.new("Hello"), Langchain::Conversation::Response.new("Hi")] }
          let(:messages) do
            [
              Langchain::Conversation::Prompt.new("Lorem " * 512),
              Langchain::Conversation::Response.new("Ipsum " * 512),
              Langchain::Conversation::Prompt.new("Dolor " * 512),
              Langchain::Conversation::Response.new("Sit " * 512)
            ]
          end

          before do
            subject.set_context(context)
            subject.add_examples(examples)
          end

          it "should drop 2 first messages and call an API" do
            expect(client).to receive(:chat).with(
              parameters: {
                max_tokens: 457,
                messages: [
                  {role: "system", content: "You are a chatbot"},
                  {role: "user", content: "Hello"},
                  {role: "assistant", content: "Hi"},
                  {role: "user", content: messages[2].content},
                  {role: "assistant", content: messages[3].content},
                  {role: "user", content: prompt}
                ],
                model: "gpt-3.5-turbo",
                n: 1,
                temperature: 0.0
              }
            ).and_return(response)

            expect(subject.message(prompt)).to be_a(Langchain::Conversation::Response)
            expect(subject.message(prompt).content).to eq("I'm doing well. How about you?")
          end
        end
      end

      context "with PaLM2 LLM" do
        let(:llm) { Langchain::LLM::GooglePalm.new api_key: "TEST" }
        let(:client) { double("GooglePalmApi::Client") }

        before do
          allow(client).to receive(:generate_chat_message).and_return(response)
          allow(client).to receive(:count_message_tokens) do |value|
            {"tokenCount" => value[:prompt].count(" ")}
          end
        end

        context "a single prompt that exceeds the token limit" do
          let(:prompt) { "Lorem " * 4096 }

          it "raises an error" do
            expect { subject.message(prompt) }.to raise_error(Langchain::Utils::TokenLength::TokenLimitExceeded)
          end
        end

        context "message history exceeds the token limit" do
          let(:prompt) { "Lorem " * 2048 }
          let(:response) do
            {"candidates" => [{"content" => "I'm doing well. How about you?"}]}
          end
          let(:context) { "You are a chatbot" }
          let(:examples) { [Langchain::Conversation::Prompt.new("Hello"), Langchain::Conversation::Response.new("Hi")] }
          let(:messages) do
            [
              Langchain::Conversation::Prompt.new("Lorem " * 512),
              Langchain::Conversation::Response.new("Ipsum " * 512),
              Langchain::Conversation::Prompt.new("Dolor " * 512),
              Langchain::Conversation::Response.new("Sit " * 512)
            ]
          end

          before do
            subject.set_context(context)
            subject.add_examples(examples)
          end

          it "should drop 2 first messages and call an API" do
            expect(client).to receive(:generate_chat_message).with(
              context: "You are a chatbot",
              examples: [
                {input: {content: "Hello"}, output: {content: "Hi"}}
              ],
              messages: [
                {author: "ai", content: messages[1].content},
                {author: "user", content: messages[2].content},
                {author: "ai", content: messages[3].content},
                {author: "user", content: prompt}
              ],
              temperature: 0.0,
              model: "chat-bison-001"
            ).and_return(response)

            expect(subject.message(prompt)).to be_a(Langchain::Conversation::Response)
            expect(subject.message(prompt).content).to eq("I'm doing well. How about you?")
          end
        end
      end
    end

    context "with length limit exceeded and summarize strategy" do
      let(:llm) { Langchain::LLM::OpenAI.new api_key: "TEST" }
      let(:client) { double("OpenAI::Client") }
      let(:prompt) { "Lorem " * 2048 }
      let(:response) do
        {"choices" => [{"message" => {"content" => "I'm doing well. How about you?"}}]}
      end
      let(:context) { "You are a chatbot" }
      let(:summary1) { "Just chatting about life" }
      let(:summary2) { "Nothing interesting here" }
      let(:examples) { [Langchain::Conversation::Prompt.new("Hello"), Langchain::Conversation::Response.new("Hi")] }
      let(:messages) do
        [
          Langchain::Conversation::Prompt.new("Lorem " * 512),
          Langchain::Conversation::Response.new("Ipsum " * 512),
          Langchain::Conversation::Prompt.new("Dolor " * 512),
          Langchain::Conversation::Response.new("Sit " * 512)
        ]
      end

      subject { described_class.new(llm: llm, messages: messages, memory_strategy: :summarize) }

      before do
        allow(llm).to receive(:client).and_return(client)
        allow(client).to receive(:chat).and_return(response)
        allow(llm).to receive(:summarize).and_return(summary1, summary2)

        subject.set_context(context)
        subject.add_examples(examples)
      end

      it "should summarize previous messages" do
        expect(client).to receive(:chat).with(
          parameters: {
            max_tokens: 2000,
            messages: [
              {role: "system", content: "You are a chatbot\nJust chatting about life\nNothing interesting here"},
              {role: "user", content: "Hello"},
              {role: "assistant", content: "Hi"},
              {role: "user", content: prompt}
            ],
            model: "gpt-3.5-turbo",
            n: 1,
            temperature: 0.0
          }
        ).and_return(response)

        expect(subject.message(prompt)).to be_a(Langchain::Conversation::Response)
        expect(subject.message(prompt).content).to eq("I'm doing well. How about you?")
      end
    end
  end
end
