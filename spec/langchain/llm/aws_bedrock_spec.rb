# frozen_string_literal: true

require "aws-sdk-bedrockruntime"

RSpec.describe Langchain::LLM::AwsBedrock do
  let(:subject) { described_class.new }

  before do
    stub_const("ENV", ENV.to_hash.merge("AWS_REGION" => "us-east-1"))
  end

  describe "#chat" do
    context "with anthropic provider" do
      let(:response) do
        {
          id: "msg_01ABdF2QG2VwivLdTmJhW8r5",
          type: "message",
          role: "assistant",
          content: [{type: "text", text: "The capital of France is Paris."}],
          model: "claude-3-sonnet-28k-20240229",
          stop_reason: "end_turn",
          stop_sequences: ["stop"],
          usage: {input_tokens: 14, output_tokens: 10}
        }.to_json
      end

      let(:model_id) { "anthropic.claude-3-sonnet-20240229-v1:0" }

      before do
        response_object = double("response_object")
        allow(response_object).to receive(:body).and_return(StringIO.new(response))
        allow(subject.client).to receive(:invoke_model)
          .with(matching(
            model_id:,
            body: {
              messages: [{role: "user", content: "What is the capital of France?"}],
              stop_sequences: ["stop"],
              max_tokens: 300,
              anthropic_version: "bedrock-2023-05-31"
            }.to_json,
            content_type: "application/json",
            accept: "application/json"
          ))
          .and_return(response_object)
      end

      it "returns a completion" do
        expect(
          subject.chat(
            messages: [{role: "user", content: "What is the capital of France?"}],
            model: model_id,
            stop_sequences: ["stop"]
          ).chat_completion
        ).to eq("The capital of France is Paris.")
      end

      context "without default model" do
        let(:model_id) { "anthropic.claude-3-5-sonnet-20240620-v1:0" }

        it "returns a completion" do
          expect(
            subject.chat(
              messages: [{role: "user", content: "What is the capital of France?"}],
              stop_sequences: ["stop"]
            ).chat_completion
          ).to eq("The capital of France is Paris.")
        end
      end

      context "with streaming" do
        let(:chunks) do
          [
            {"type" => "message_start", "message" => {"id" => "msg_abcdefg", "type" => "message", "role" => "assistant", "content" => [], "model" => "anthropic.claude-3-sonnet-20240229-v1:0", "stop_reason" => nil, "stop_sequence" => nil, "usage" => {"input_tokens" => 17, "output_tokens" => 1}}},
            {"type" => "content_block_start", "index" => 0, "content_block" => {"type" => "text", "text" => ""}},
            {"type" => "content_block_delta", "index" => 0, "delta" => {"type" => "text_delta", "text" => "The"}},
            {"type" => "content_block_delta", "index" => 0, "delta" => {"type" => "text_delta", "text" => " capital of France"}},
            {"type" => "content_block_delta", "index" => 0, "delta" => {"type" => "text_delta", "text" => " is Paris."}},
            {"type" => "content_block_stop", "index" => 0},
            {"type" => "message_delta", "delta" => {"stop_reason" => "end_turn", "stop_sequence" => nil}, "usage" => {"output_tokens" => 10}},
            {"type" => "message_stop", "amazon-bedrock-invocationMetrics" => {"inputTokenCount" => 17, "outputTokenCount" => 10, "invocationLatency" => 1234, "firstByteLatency" => 567}}
          ]
        end

        before do
          mock_stream = double("stream")
          allow(mock_stream).to receive(:on_event) do |&block|
            chunks.each do |chunk|
              mock_event = double("event", bytes: chunk.to_json)
              block.call(mock_event)
            end
          end
          allow(subject.client).to receive(:invoke_model_with_response_stream)
            .with(matching(
              model_id: "anthropic.claude-3-sonnet-20240229-v1:0",
              body: {
                messages: [{role: "user", content: "What is the capital of France?"}],
                stop_sequences: ["stop"],
                max_tokens: 300,
                anthropic_version: "bedrock-2023-05-31"
              }.to_json,
              content_type: "application/json",
              accept: "application/json"
            )).and_yield(mock_stream)
        end

        it "yields chunks and returns a completion" do
          i = 0
          response = subject.chat(
            messages: [{role: "user", content: "What is the capital of France?"}],
            model: "anthropic.claude-3-sonnet-20240229-v1:0",
            stop_sequences: ["stop"]
          ) do |chunk|
            expect(chunk).to eq(chunks[i])
            i += 1
          end

          expect(response).to be_a(Langchain::LLM::AnthropicResponse)
          expect(response.chat_completion).to eq("The capital of France is Paris.")
        end
      end
    end
  end

  describe "#complete" do
    context "with anthropic provider" do
      let(:response) do
        StringIO.new("{\"completion\":\"\\nWhat is the meaning of life? What is the meaning of life?\\nWhat is the meaning\"}")
      end

      let(:expected_body) do
        {
          anthropic_version: "bedrock-2023-05-31",
          prompt: "\n\nHuman: Hello World\n\nAssistant:"
        }
      end

      context "with no additional parameters" do
        before do
          response_object = double("response_object")
          allow(response_object).to receive(:body).and_return(response)
          allow(subject.client).to receive(:invoke_model)
            .with({model_id: "anthropic.claude-v2:1", body: expected_body.to_json, content_type: "application/json", accept: "application/json"})
            .and_return(response_object)
        end

        it "returns a completion" do
          expect(subject.complete(prompt: "Hello World").completion).to eq("\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning")
        end
      end

      context "with additional parameters" do
        let(:expected_body) do
          {
            temperature: 0.7,
            max_tokens_to_sample: 100,
            anthropic_version: "bedrock-2023-05-31",
            prompt: "\n\nHuman: Hello World\n\nAssistant:"
          }
        end

        before do
          response_object = double("response_object")
          allow(response_object).to receive(:body).and_return(response)
          allow(subject.client).to receive(:invoke_model)
            .with({model_id: "anthropic.claude-v2:1", body: expected_body.to_json, content_type: "application/json", accept: "application/json"})
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
            anthropic_version: "bedrock-2023-05-31",
            prompt: "\n\nHuman: Hello World\n\nAssistant:"
          }
        end

        before do
          allow(response_object).to receive(:body).and_return(response)
          allow(subject.client).to receive(:invoke_model)
            .with({model_id: "anthropic.claude-v2:1", body: expected_body.to_json, content_type: "application/json", accept: "application/json"})
            .and_return(response_object)
        end

        it "passes correct options to the client's complete method" do
          expect(subject.client).to receive(:invoke_model).with({model_id: "anthropic.claude-v2:1", body: expected_body.to_json, content_type: "application/json", accept: "application/json"}).and_return(response_object)

          expect(subject.complete(prompt: "Hello World").completion).to eq("\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning")
        end
      end
    end

    context "with ai21 provider" do
      let(:subject) { described_class.new(default_options: {completion_model: "ai21.j2-ultra-v1"}) }

      let(:response) do
        StringIO.new("{\"completions\":[{\"data\":{\"text\":\"\\nWhat is the meaning of life? What is the meaning of life?\\nWhat is the meaning\"}}]}")
      end

      let(:expected_body) do
        {
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
            temperature: 0.7,
            max_tokens: 100,
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
          expect(subject.complete(prompt: "Hello World", temperature: 0.7, max_tokens: 100).completion).to eq(
            "\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning"
          )
        end
      end

      context "with custom default_options" do
        let(:subject) {
          described_class.new(
            default_options: {
              completion_model: "ai21.j2-ultra-v1",
              max_tokens_to_sample: 100,
              temperature: 0.7
            }
          )
        }
        let(:response_object) { double("response_object") }
        let(:expected_body) do
          {
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
      let(:subject) { described_class.new(default_options: {completion_model: "cohere.command-text-v14"}) }

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
            default_options: {
              completion_model: "cohere.command-text-v14",
              max_tokens_to_sample: 100,
              temperature: 0.7
            }
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
      let(:subject) { described_class.new(default_options: {completion_model: "unsupported.provider"}) }

      it "raises an exception" do
        expect { subject.complete(prompt: "Hello World") }.to raise_error("Completion provider unsupported.provider is not supported.")
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

    context "with cohere provider" do
      let(:subject) { described_class.new(default_options: {embedding_model: "cohere.embed-multilingual-v3"}) }

      let(:response) do
        StringIO.new("{\"embeddings\":[[0.1,0.2,0.3,0.4,0.5]]}")
      end

      let(:expected_body) do
        {
          texts: ["Hello World"],
          input_type: "search_document",
          embedding_types: ["float"]
        }
      end

      before do
        response_object = double("response_object")
        allow(response_object).to receive(:body).and_return(response)
        allow(subject.client).to receive(:invoke_model)
          .with({model_id: "cohere.embed-multilingual-v3", body: expected_body.to_json, content_type: "application/json", accept: "application/json"})
          .and_return(response_object)
      end

      it "returns a embedding" do
        expect(
          subject.embed(text: "Hello World", input_type: "search_document", embedding_types: ["float"]).embedding
        ).to eq([0.1, 0.2, 0.3, 0.4, 0.5])
      end
    end

    context "with unsupported provider" do
      let(:subject) { described_class.new(default_options: {embedding_model: "unsupported.provider"}) }

      it "raises an exception" do
        expect { subject.embed(text: "Hello World") }.to raise_error("Completion provider unsupported is not supported.")
      end
    end
  end

  describe "#response_from_chunks" do
    let(:chunks) do
      [
        {"type" => "message_start", "message" => {"id" => "msg_abcdefg", "type" => "message", "role" => "assistant", "content" => [], "model" => "anthropic.claude-3-sonnet-20240229-v1:0", "stop_reason" => nil, "stop_sequence" => nil, "usage" => {"input_tokens" => 17, "output_tokens" => 1}}},
        {"type" => "content_block_start", "index" => 0, "content_block" => {"type" => "text", "text" => ""}},
        {"type" => "content_block_delta", "index" => 0, "delta" => {"type" => "text_delta", "text" => "The"}},
        {"type" => "content_block_delta", "index" => 0, "delta" => {"type" => "text_delta", "text" => " capital of France"}},
        {"type" => "content_block_delta", "index" => 0, "delta" => {"type" => "text_delta", "text" => " is Paris."}},
        {"type" => "content_block_stop", "index" => 0},
        {"type" => "message_delta", "delta" => {"stop_reason" => "end_turn", "stop_sequence" => nil}, "usage" => {"output_tokens" => 10}},
        {"type" => "message_stop", "amazon-bedrock-invocationMetrics" => {"inputTokenCount" => 17, "outputTokenCount" => 10, "invocationLatency" => 1234, "firstByteLatency" => 567}}
      ]
    end

    it "returns an AnthropicResponse" do
      response = subject.send(:response_from_chunks, chunks)

      expect(response).to be_a(Langchain::LLM::AnthropicResponse)
      expect(response.chat_completion).to eq("The capital of France is Paris.")
    end

    it "returns the correct raw response" do
      response = subject.send(:response_from_chunks, chunks)

      expect(response.raw_response).to eq({
        "id" => "msg_abcdefg",
        "type" => "message",
        "role" => "assistant",
        "content" => [{"type" => "text", "text" => "The capital of France is Paris."}],
        "model" => "anthropic.claude-3-sonnet-20240229-v1:0",
        "stop_reason" => "end_turn",
        "stop_sequence" => nil,
        "usage" => {"input_tokens" => 17, "output_tokens" => 10}
      })
    end

    context "with multiple content blocks" do
      let(:chunks) do
        [
          {"type" => "message_start", "message" => {"id" => "msg_abcdefg", "type" => "message", "role" => "assistant", "content" => [], "model" => "anthropic.claude-3-sonnet-20240229-v1:0", "stop_reason" => nil, "stop_sequence" => nil, "usage" => {"input_tokens" => 17, "output_tokens" => 1}}},
          {"type" => "content_block_start", "index" => 0, "content_block" => {"type" => "text", "text" => ""}},
          {"type" => "content_block_delta", "index" => 0, "delta" => {"type" => "text_delta", "text" => "The"}},
          {"type" => "content_block_delta", "index" => 0, "delta" => {"type" => "text_delta", "text" => " capital of France"}},
          {"type" => "content_block_delta", "index" => 0, "delta" => {"type" => "text_delta", "text" => " is Paris."}},
          {"type" => "content_block_stop", "index" => 0},
          {"type" => "content_block_start", "index" => 1, "content_block" => {"type" => "text", "text" => ""}},
          {"type" => "content_block_delta", "index" => 1, "delta" => {"type" => "text_delta", "text" => "The"}},
          {"type" => "content_block_delta", "index" => 1, "delta" => {"type" => "text_delta", "text" => " capital of Chile"}},
          {"type" => "content_block_delta", "index" => 1, "delta" => {"type" => "text_delta", "text" => " is Santiago."}},
          {"type" => "content_block_stop", "index" => 1},
          {"type" => "message_delta", "delta" => {"stop_reason" => "end_turn", "stop_sequence" => nil}, "usage" => {"output_tokens" => 20}},
          {"type" => "message_stop", "amazon-bedrock-invocationMetrics" => {"inputTokenCount" => 17, "outputTokenCount" => 20, "invocationLatency" => 1234, "firstByteLatency" => 567}}
        ]
      end

      it "returns the correct raw response" do
        response = subject.send(:response_from_chunks, chunks)

        expect(response.raw_response).to eq({
          "id" => "msg_abcdefg",
          "type" => "message",
          "role" => "assistant",
          "content" => [
            {"type" => "text", "text" => "The capital of France is Paris."},
            {"type" => "text", "text" => "The capital of Chile is Santiago."}
          ],
          "model" => "anthropic.claude-3-sonnet-20240229-v1:0",
          "stop_reason" => "end_turn",
          "stop_sequence" => nil,
          "usage" => {"input_tokens" => 17, "output_tokens" => 20}
        })
      end

      context "with input json deltas" do
        let(:chunks) do
          [
            {"type" => "message_start", "message" => {"id" => "msg_abcdefg", "type" => "message", "role" => "assistant", "content" => [], "model" => "anthropic.claude-3-sonnet-20240229-v1:0", "stop_reason" => nil, "stop_sequence" => nil, "usage" => {"input_tokens" => 17, "output_tokens" => 1}}},
            {"type" => "content_block_start", "index" => 0, "content_block" => {"type" => "text", "text" => ""}},
            {"type" => "content_block_delta", "index" => 0, "delta" => {"type" => "text_delta", "text" => "The"}},
            {"type" => "content_block_delta", "index" => 0, "delta" => {"type" => "text_delta", "text" => " capital of France"}},
            {"type" => "content_block_delta", "index" => 0, "delta" => {"type" => "text_delta", "text" => " is Paris."}},
            {"type" => "content_block_stop", "index" => 0},
            {"type" => "content_block_start", "index" => 1, "content_block" => {"type" => "tool_use", "id" => "toolu_abc", "name" => "population", "input" => {}}},
            {"type" => "content_block_delta", "index" => 1, "delta" => {"type" => "input_json_delta", "partial_json" => ""}},
            {"type" => "content_block_delta", "index" => 1, "delta" => {"type" => "input_json_delta", "partial_json" => "{\"ci"}},
            {"type" => "content_block_delta", "index" => 1, "delta" => {"type" => "input_json_delta", "partial_json" => "ty\": \"Pari"}},
            {"type" => "content_block_delta", "index" => 1, "delta" => {"type" => "input_json_delta", "partial_json" => "s\", \"countr"}},
            {"type" => "content_block_delta", "index" => 1, "delta" => {"type" => "input_json_delta", "partial_json" => "y\""}},
            {"type" => "content_block_delta", "index" => 1, "delta" => {"type" => "input_json_delta", "partial_json" => ": \"France\"}"}},
            {"type" => "message_delta", "delta" => {"stop_reason" => "end_turn", "stop_sequence" => nil}, "usage" => {"output_tokens" => 20}},
            {"type" => "message_stop", "amazon-bedrock-invocationMetrics" => {"inputTokenCount" => 17, "outputTokenCount" => 20, "invocationLatency" => 1234, "firstByteLatency" => 567}}
          ]
        end

        it "returns the correct raw response" do
          response = subject.send(:response_from_chunks, chunks)

          expect(response.raw_response).to eq({
            "id" => "msg_abcdefg",
            "type" => "message",
            "role" => "assistant",
            "content" => [
              {"type" => "text", "text" => "The capital of France is Paris."},
              {"type" => "tool_use", "id" => "toolu_abc", "name" => "population", "input" => {"city" => "Paris", "country" => "France"}}
            ],
            "model" => "anthropic.claude-3-sonnet-20240229-v1:0",
            "stop_reason" => "end_turn",
            "stop_sequence" => nil,
            "usage" => {"input_tokens" => 17, "output_tokens" => 20}
          })
        end
      end

      context "with empty input json deltas" do
        let(:chunks) do
          [
            {"type" => "message_start", "message" => {"id" => "msg_abcdefg", "type" => "message", "role" => "assistant", "content" => [], "model" => "anthropic.claude-3-sonnet-20240229-v1:0", "stop_reason" => nil, "stop_sequence" => nil, "usage" => {"input_tokens" => 17, "output_tokens" => 1}}},
            {"type" => "content_block_start", "index" => 0, "content_block" => {"type" => "text", "text" => ""}},
            {"type" => "content_block_delta", "index" => 0, "delta" => {"type" => "text_delta", "text" => "The"}},
            {"type" => "content_block_delta", "index" => 0, "delta" => {"type" => "text_delta", "text" => " capital of France"}},
            {"type" => "content_block_delta", "index" => 0, "delta" => {"type" => "text_delta", "text" => " is Paris."}},
            {"type" => "content_block_stop", "index" => 0},
            {"type" => "content_block_start", "index" => 1, "content_block" => {"type" => "tool_use", "id" => "toolu_abc", "name" => "population", "input" => {}}},
            {"type" => "content_block_delta", "index" => 1, "delta" => {"type" => "input_json_delta", "partial_json" => ""}},
            {"type" => "message_delta", "delta" => {"stop_reason" => "end_turn", "stop_sequence" => nil}, "usage" => {"output_tokens" => 20}},
            {"type" => "message_stop", "amazon-bedrock-invocationMetrics" => {"inputTokenCount" => 17, "outputTokenCount" => 20, "invocationLatency" => 1234, "firstByteLatency" => 567}}
          ]
        end

        it "returns the correct raw response" do
          response = subject.send(:response_from_chunks, chunks)

          expect(response.raw_response).to eq({
            "id" => "msg_abcdefg",
            "type" => "message",
            "role" => "assistant",
            "content" => [
              {"type" => "text", "text" => "The capital of France is Paris."},
              {"type" => "tool_use", "id" => "toolu_abc", "name" => "population", "input" => {}}
            ],
            "model" => "anthropic.claude-3-sonnet-20240229-v1:0",
            "stop_reason" => "end_turn",
            "stop_sequence" => nil,
            "usage" => {"input_tokens" => 17, "output_tokens" => 20}
          })
        end
      end
    end
  end
end
