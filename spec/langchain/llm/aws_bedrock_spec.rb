# frozen_string_literal: true

require "aws-sdk-bedrockruntime"

RSpec.describe Langchain::LLM::AwsBedrock do
  let(:subject) { described_class.new }

  before do
    stub_const("ENV", ENV.to_hash.merge("AWS_REGION" => "us-east-1"))
  end

  describe "#complete" do
    context "with anthropic provider" do
      let(:response) do
        StringIO.new("{\"completion\":\"\\nWhat is the meaning of life? What is the meaning of life?\\nWhat is the meaning\"}")
      end

      let(:expected_body) do
        {
          max_tokens_to_sample: 300,
          temperature: 1,
          top_k: 250,
          top_p: 0.999,
          stop_sequences: ["\n\nHuman:"],
          anthropic_version: "bedrock-2023-05-31",
          prompt: "\n\nHuman: Hello World\n\nAssistant:"
        }
      end

      context "with no additional parameters" do
        before do
          response_object = double("response_object")
          allow(response_object).to receive(:body).and_return(response)
          allow(subject.client).to receive(:invoke_model)
            .with({model_id: "anthropic.claude-v2", body: expected_body.to_json, content_type: "application/json", accept: "application/json"})
            .and_return(response_object)
        end

        it "returns a completion" do
          expect(subject.complete(prompt: "Hello World").completion).to eq("\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning")
        end
      end

      context "with additional parameters" do
        let(:expected_body) do
          {
            max_tokens_to_sample: 100,
            temperature: 0.7,
            top_k: 250,
            top_p: 0.999,
            stop_sequences: ["\n\nHuman:"],
            anthropic_version: "bedrock-2023-05-31",
            prompt: "\n\nHuman: Hello World\n\nAssistant:"
          }
        end

        before do
          response_object = double("response_object")
          allow(response_object).to receive(:body).and_return(response)
          allow(subject.client).to receive(:invoke_model)
            .with({model_id: "anthropic.claude-v2", body: expected_body.to_json, content_type: "application/json", accept: "application/json"})
            .and_return(response_object)
        end

        it "returns a completion" do
          expect(subject.complete(prompt: "Hello World", temperature: 0.7, max_tokens_to_sample: 100).completion).to eq(
            "\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning"
          )
        end
      end

      context "with custom default_options" do
        let(:subject) {
          described_class.new(
            default_options: {max_tokens_to_sample: 100, temperature: 0.7}
          )
        }
        let(:response_object) { double("response_object") }
        let(:expected_body) do
          {
            max_tokens_to_sample: 100,
            temperature: 0.7,
            top_k: 250,
            top_p: 0.999,
            stop_sequences: ["\n\nHuman:"],
            anthropic_version: "bedrock-2023-05-31",
            prompt: "\n\nHuman: Hello World\n\nAssistant:"
          }
        end

        before do
          allow(response_object).to receive(:body).and_return(response)
          allow(subject.client).to receive(:invoke_model)
            .with({model_id: "anthropic.claude-v2", body: expected_body.to_json, content_type: "application/json", accept: "application/json"})
            .and_return(response_object)
        end

        it "passes correct options to the client's complete method" do
          expect(subject.client).to receive(:invoke_model).with({model_id: "anthropic.claude-v2", body: expected_body.to_json, content_type: "application/json", accept: "application/json"}).and_return(response_object)

          expect(subject.complete(prompt: "Hello World").completion).to eq("\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning")
        end
      end
    end

    context "with ai21 provider" do
      let(:subject) { described_class.new(completion_model: "ai21.j2-ultra-v1") }

      let(:response) do
        StringIO.new("{\"completions\":[{\"data\":{\"text\":\"\\nWhat is the meaning of life? What is the meaning of life?\\nWhat is the meaning\"}}]}")
      end

      let(:expected_body) do
        {
          maxTokens: 300,
          temperature: 1,
          topP: 0.999,
          stopSequences: ["\n\nHuman:"],
          countPenalty: {
            scale: 0,
            applyToWhitespaces: false,
            applyToPunctuations: false,
            applyToNumbers: false,
            applyToStopwords: false,
            applyToEmojis: false
          },
          presencePenalty: {
            scale: 0,
            applyToWhitespaces: false,
            applyToPunctuations: false,
            applyToNumbers: false,
            applyToStopwords: false,
            applyToEmojis: false
          },
          frequencyPenalty: {
            scale: 0,
            applyToWhitespaces: false,
            applyToPunctuations: false,
            applyToNumbers: false,
            applyToStopwords: false,
            applyToEmojis: false
          },
          prompt: "Hello World"
        }
      end

      context "with no additional parameters" do
        before do
          response_object = double("response_object")
          allow(response_object).to receive(:body).and_return(response)
          allow(subject.client).to receive(:invoke_model)
            .with({model_id: "ai21.j2-ultra-v1", body: expected_body.to_json, content_type: "application/json", accept: "application/json"})
            .and_return(response_object)
        end

        it "returns a completion" do
          expect(subject.complete(prompt: "Hello World").completion).to eq("\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning")
        end
      end

      context "with additional parameters" do
        let(:expected_body) do
          {
            maxTokens: 100,
            temperature: 0.7,
            topP: 0.999,
            stopSequences: ["\n\nHuman:"],
            countPenalty: {
              scale: 0,
              applyToWhitespaces: false,
              applyToPunctuations: false,
              applyToNumbers: false,
              applyToStopwords: false,
              applyToEmojis: false
            },
            presencePenalty: {
              scale: 0,
              applyToWhitespaces: false,
              applyToPunctuations: false,
              applyToNumbers: false,
              applyToStopwords: false,
              applyToEmojis: false
            },
            frequencyPenalty: {
              scale: 0,
              applyToWhitespaces: false,
              applyToPunctuations: false,
              applyToNumbers: false,
              applyToStopwords: false,
              applyToEmojis: false
            },
            prompt: "Hello World"
          }
        end

        before do
          response_object = double("response_object")
          allow(response_object).to receive(:body).and_return(response)
          allow(subject.client).to receive(:invoke_model)
            .with({model_id: "ai21.j2-ultra-v1", body: expected_body.to_json, content_type: "application/json", accept: "application/json"})
            .and_return(response_object)
        end

        it "returns a completion" do
          expect(subject.complete(prompt: "Hello World", temperature: 0.7, max_tokens_to_sample: 100).completion).to eq(
            "\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning"
          )
        end
      end

      context "with custom default_options" do
        let(:subject) {
          described_class.new(
            completion_model: "ai21.j2-ultra-v1",
            default_options: {max_tokens_to_sample: 100, temperature: 0.7}
          )
        }
        let(:response_object) { double("response_object") }
        let(:expected_body) do
          {
            maxTokens: 100,
            temperature: 0.7,
            topP: 0.999,
            stopSequences: ["\n\nHuman:"],
            countPenalty: {
              scale: 0,
              applyToWhitespaces: false,
              applyToPunctuations: false,
              applyToNumbers: false,
              applyToStopwords: false,
              applyToEmojis: false
            },
            presencePenalty: {
              scale: 0,
              applyToWhitespaces: false,
              applyToPunctuations: false,
              applyToNumbers: false,
              applyToStopwords: false,
              applyToEmojis: false
            },
            frequencyPenalty: {
              scale: 0,
              applyToWhitespaces: false,
              applyToPunctuations: false,
              applyToNumbers: false,
              applyToStopwords: false,
              applyToEmojis: false
            },
            prompt: "Hello World"
          }
        end

        before do
          allow(response_object).to receive(:body).and_return(response)
          allow(subject.client).to receive(:invoke_model)
            .with({model_id: "ai21.j2-ultra-v1", body: expected_body.to_json, content_type: "application/json", accept: "application/json"})
            .and_return(response_object)
        end

        it "passes correct options to the client's complete method" do
          expect(subject.client).to receive(:invoke_model).with({model_id: "ai21.j2-ultra-v1", body: expected_body.to_json, content_type: "application/json", accept: "application/json"}).and_return(response_object)

          expect(subject.complete(prompt: "Hello World").completion).to eq("\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning")
        end
      end
    end

    context "with cohere provider" do
      let(:subject) { described_class.new(completion_model: "cohere.command-text-v14") }

      let(:response) do
        StringIO.new("{\"generations\":[{\"text\":\"\\nWhat is the meaning of life? What is the meaning of life?\\nWhat is the meaning\"}]}")
      end

      let(:expected_body) do
        {
          max_tokens: 300,
          temperature: 1,
          p: 0.999,
          k: 250,
          stop_sequences: ["\n\nHuman:"],
          prompt: "Hello World"
        }
      end

      context "with no additional parameters" do
        before do
          response_object = double("response_object")
          allow(response_object).to receive(:body).and_return(response)
          allow(subject.client).to receive(:invoke_model)
            .with({model_id: "cohere.command-text-v14", body: expected_body.to_json, content_type: "application/json", accept: "application/json"})
            .and_return(response_object)
        end

        it "returns a completion" do
          expect(subject.complete(prompt: "Hello World").completion).to eq("\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning")
        end
      end

      context "with additional parameters" do
        let(:expected_body) do
          {
            max_tokens: 100,
            temperature: 0.7,
            p: 0.999,
            k: 250,
            stop_sequences: ["\n\nHuman:"],
            prompt: "Hello World"
          }
        end

        before do
          response_object = double("response_object")
          allow(response_object).to receive(:body).and_return(response)
          allow(subject.client).to receive(:invoke_model)
            .with({model_id: "cohere.command-text-v14", body: expected_body.to_json, content_type: "application/json", accept: "application/json"})
            .and_return(response_object)
        end

        it "returns a completion" do
          expect(subject.complete(prompt: "Hello World", temperature: 0.7, max_tokens_to_sample: 100).completion).to eq(
            "\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning"
          )
        end
      end

      context "with custom default_options" do
        let(:subject) {
          described_class.new(
            completion_model: "cohere.command-text-v14",
            default_options: {max_tokens_to_sample: 100, temperature: 0.7}
          )
        }
        let(:response_object) { double("response_object") }
        let(:expected_body) do
          {
            max_tokens: 100,
            temperature: 0.7,
            p: 0.999,
            k: 250,
            stop_sequences: ["\n\nHuman:"],
            prompt: "Hello World"
          }
        end

        before do
          allow(response_object).to receive(:body).and_return(response)
          allow(subject.client).to receive(:invoke_model)
            .with({model_id: "cohere.command-text-v14", body: expected_body.to_json, content_type: "application/json", accept: "application/json"})
            .and_return(response_object)
        end

        it "passes correct options to the client's complete method" do
          expect(subject.client).to receive(:invoke_model).with({model_id: "cohere.command-text-v14", body: expected_body.to_json, content_type: "application/json", accept: "application/json"}).and_return(response_object)

          expect(subject.complete(prompt: "Hello World").completion).to eq("\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning")
        end
      end
    end

    context "with unsupported provider" do
      let(:subject) { described_class.new(completion_model: "unsupported.provider") }

      it "raises an exception" do
        expect { subject.complete(prompt: "Hello World") }.to raise_error("Completion provider unsupported is not supported.")
      end
    end
  end

  describe "#embed" do
    context "with amazon provider" do
      let(:response) do
        StringIO.new("{\"embedding\":[0.1,0.2,0.3,0.4,0.5]}")
      end

      let(:expected_body) do
        {
          inputText: "Hello World"
        }
      end

      context "with no additional parameters" do
        before do
          response_object = double("response_object")
          allow(response_object).to receive(:body).and_return(response)
          allow(subject.client).to receive(:invoke_model)
            .with({model_id: "amazon.titan-embed-text-v1", body: expected_body.to_json, content_type: "application/json", accept: "application/json"})
            .and_return(response_object)
        end

        it "returns a embedding" do
          expect(subject.embed(text: "Hello World").embedding).to eq([0.1, 0.2, 0.3, 0.4, 0.5])
        end
      end
    end

    context "with unsupported provider" do
      let(:subject) { described_class.new(embedding_model: "unsupported.provider") }

      it "raises an exception" do
        expect { subject.embed(text: "Hello World") }.to raise_error("Completion provider unsupported is not supported.")
      end
    end
  end
end
