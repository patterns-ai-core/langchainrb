# frozen_string_literal: true

require "openai"

RSpec.describe Langchain::LLM::OpenAI do
  let(:subject) { described_class.new(api_key: "123", **options) }

  let(:options) { {} }

  describe "#initialize" do
    it "initializes the client without any errors" do
      expect { subject }.not_to raise_error
    end

    it "forwards the Langchain logger to the client" do
      f_mock = double("f_mock", response: nil)

      allow(OpenAI::Client).to receive(:new) { |**, &block| block&.call(f_mock) }

      subject

      expect(f_mock).to have_received(:response).with(:logger, Langchain.logger, anything)
    end

    context "when log level is DEBUG" do
      before do
        Langchain.logger.level = Logger::DEBUG
      end

      it "configures the client to log the errors" do
        allow(OpenAI::Client).to receive(:new).and_call_original
        subject
        expect(OpenAI::Client).to have_received(:new).with(hash_including(log_errors: true))
      end

      context "when overriding the 'log_errors' param" do
        let(:options) { {llm_options: {log_errors: false}} }

        it "configures the client to NOT log the errors" do
          allow(OpenAI::Client).to receive(:new).and_call_original
          subject
          expect(OpenAI::Client).to have_received(:new).with(hash_including(log_errors: false))
        end
      end
    end

    context "when log level is not DEBUG" do
      before do
        Langchain.logger.level = Logger::INFO
      end

      it "configures the client to NOT log the errors" do
        allow(OpenAI::Client).to receive(:new).and_call_original
        subject
        expect(OpenAI::Client).to have_received(:new).with(hash_including(log_errors: false))
      end

      context "when overriding the 'log_errors' param" do
        let(:options) { {llm_options: {log_errors: true}} }

        it "configures the client to log the errors" do
          allow(OpenAI::Client).to receive(:new).and_call_original
          subject
          expect(OpenAI::Client).to have_received(:new).with(hash_including(log_errors: true))
        end
      end
    end

    context "when llm_options are passed" do
      let(:options) { {llm_options: {uri_base: "http://localhost:1234"}} }

      it "initializes the client without any errors" do
        expect { subject }.not_to raise_error
      end

      it "passes correct options to the client" do
        # openai-ruby sets global configuration options here: https://github.com/alexrudall/ruby-openai/blob/main/lib/openai/client.rb
        result = subject
        expect(result.client.uri_base).to eq("http://localhost:1234")
      end
    end

    context "when default_options are passed" do
      let(:default_options) { {response_format: {type: "json_object"}} }

      subject { described_class.new(api_key: "123", default_options: default_options) }

      it "sets the defaults options" do
        expect(subject.defaults[:response_format]).to eq(type: "json_object")
      end

      it "get passed to consecutive chat() call" do
        subject
        expect(subject.client).to receive(:chat).with(parameters: hash_including(default_options)).and_return({})
        subject.chat(messages: [{role: "user", content: "Hello json!"}])
      end

      it "can be overridden" do
        subject
        expect(subject.client).to receive(:chat).with(parameters: hash_including({response_format: {type: "text"}})).and_return({})
        subject.chat(messages: [{role: "user", content: "Hello json!"}], response_format: {type: "text"})
      end
    end
  end

  describe "#embed" do
    let(:result) { [-0.007097351, 0.0035200312, -0.0069700438] }
    let(:parameters) do
      {parameters: {
        input: "Hello World",
        model: "text-embedding-3-small",
        dimensions: 1536
      }}
    end
    let(:response) do
      {
        "object" => "list",
        "model" => parameters[:parameters][:model],
        "data" => [
          {
            "object" => "embedding",
            "index" => 0,
            "embedding" => result
          }
        ],
        "usage" => {
          "prompt_tokens" => 2,
          "total_tokens" => 2
        }
      }
    end

    before do
      allow(subject.client).to receive(:embeddings).with(parameters).and_return(response)
    end

    it "returns valid llm response object" do
      response = subject.embed(text: "Hello World")

      expect(response).to be_a(Langchain::LLM::OpenAIResponse)
      expect(response.model).to eq("text-embedding-3-small")
      expect(response.embedding).to eq([-0.007097351, 0.0035200312, -0.0069700438])
      expect(response.prompt_tokens).to eq(2)
      expect(response.completion_tokens).to eq(nil)
      expect(response.total_tokens).to eq(2)
    end

    context "with default parameters" do
      it "returns an embedding" do
        response = subject.embed(text: "Hello World")

        expect(response).to be_a(Langchain::LLM::OpenAIResponse)
        expect(response.embedding).to eq(result)
      end
    end

    context "with text and parameters" do
      let(:parameters) do
        {parameters: {input: "Hello World", model: "text-embedding-ada-002", user: "id"}}
      end

      it "returns an embedding" do
        response = subject.embed(text: "Hello World", model: "text-embedding-ada-002", user: "id")

        expect(response).to be_a(Langchain::LLM::OpenAIResponse)
        expect(response.embedding).to eq(result)
      end
    end

    describe "the model dimension" do
      let(:model) { "text-embedding-3-small" }
      let(:dimensions_size) { 1536 }
      let(:parameters) do
        {parameters: {input: "Hello World", model: model, dimensions: dimensions_size}}
      end

      context "when dimensions is not provided" do
        it "forwards the models default dimensions" do
          subject.embed(text: "Hello World", model: model)

          expect(subject.client).to have_received(:embeddings).with(parameters)
        end
      end

      context "when dimensions is provided" do
        let(:dimensions_size) { 1536 }

        let(:parameters) do
          {parameters: {input: "Hello World", model: model, dimensions: dimensions_size}}
        end

        let(:subject) do
          described_class.new(api_key: "123", default_options: {
            embedding_model: model,
            dimensions: dimensions_size
          })
        end

        it "forwards the model's default dimensions" do
          allow(subject.client).to receive(:embeddings).with(parameters).and_return(response)
          subject.embed(text: "Hello World", model: model)

          expect(subject.client).to have_received(:embeddings).with(parameters)
        end
      end
    end

    Langchain::LLM::OpenAI::EMBEDDING_SIZES.each do |model_key, dimensions|
      model = model_key.to_s

      context "when using model #{model}" do
        let(:text) { "Hello World" }
        let(:result) { [0.001, 0.002, 0.003] } # Ejemplo de resultado esperado

        let(:base_parameters) do
          {
            input: text,
            model: model
          }
        end

        let(:expected_parameters) do
          base_parameters[:dimensions] = dimensions unless model == "text-embedding-ada-002"
          base_parameters
        end

        let(:response) do
          {
            "object" => "list",
            "model" => model,
            "data" => [{"object" => "embedding", "index" => 0, "embedding" => result}],
            "usage" => {"prompt_tokens" => 2, "total_tokens" => 2}
          }
        end

        before do
          allow(subject.client).to receive(:embeddings).with(parameters: expected_parameters).and_return(response)
        end

        it "generates an embedding using #{model}" do
          embedding_response = subject.embed(text: text, model: model)

          expect(embedding_response).to be_a(Langchain::LLM::OpenAIResponse)
          expect(embedding_response.model).to eq(model)
          expect(embedding_response.embedding).to eq(result)
          expect(embedding_response.prompt_tokens).to eq(2)
          expect(embedding_response.total_tokens).to eq(2)
        end
      end
    end

    context "when dimensions are explicitly provided" do
      let(:parameters) do
        {parameters: {input: "Hello World", model: "text-embedding-3-small", dimensions: 999}}
      end

      it "they are passed to the API" do
        allow(subject.client).to receive(:embeddings).with(parameters).and_return(response)
        subject.embed(text: "Hello World", model: "text-embedding-3-small", dimensions: 999)

        expect(subject.client).to have_received(:embeddings).with(parameters)
      end
    end

    context "when dimensions are explicitly provided to the initialize default options" do
      let(:subject) { described_class.new(api_key: "123", default_options: {dimensions: dimensions}) }
      let(:dimensions) { 999 }
      let(:model) { "text-embedding-3-small" }
      let(:text) { "Hello World" }
      let(:parameters) do
        {parameters: {input: text, model: model, dimensions: dimensions}}
      end

      it "they are passed to the API" do
        allow(subject.client).to receive(:embeddings).with(parameters).and_return(response)
        subject.embed(text: text, model: model)

        expect(subject.client).to have_received(:embeddings).with(parameters)
      end
    end
  end

  describe "#complete" do
    let(:response) do
      {
        "id" => "chatcmpl-9orgr5hNUdCsQeNWGnmNnbXQVIcPN",
        "object" => "chat.completion",
        "created" => 1721906887,
        "model" => "gpt-4o-mini-2024-07-18",
        "choices" => [
          {
            "message" => {
              "role" => "assistant",
              "content" => "The meaning of life is subjective and can vary from person to person."
            },
            "finish_reason" => "stop",
            "index" => 0
          }
        ],
        "usage" => {
          "prompt_tokens" => 7,
          "completion_tokens" => 16,
          "total_tokens" => 23
        }
      }
    end

    before do
      allow(subject.client).to receive(:chat).with(parameters).and_return(response)
      allow(subject.client).to receive(:chat).with(parameters).and_return(response)
    end

    context "with default parameters" do
      let(:parameters) do
        {
          parameters: {
            n: 1,
            model: "gpt-4o-mini",
            messages: [{content: "Hello World", role: "user"}]
          }
        }
      end

      it "returns valid llm response object" do
        response = subject.complete(prompt: "Hello World")

        expect(response).to be_a(Langchain::LLM::OpenAIResponse)
        expect(response.model).to eq("gpt-4o-mini-2024-07-18")
        expect(response.completion).to eq("The meaning of life is subjective and can vary from person to person.")
        expect(response.prompt_tokens).to eq(7)
        expect(response.completion_tokens).to eq(16)
        expect(response.total_tokens).to eq(23)
      end

      it "returns a completion" do
        response = subject.complete(prompt: "Hello World")

        expect(response).to be_a(Langchain::LLM::OpenAIResponse)
        expect(response.model).to eq("gpt-4o-mini-2024-07-18")
        expect(response.completions).to eq([{"message" => {"role" => "assistant", "content" => "The meaning of life is subjective and can vary from person to person."}, "finish_reason" => "stop", "index" => 0}])
        expect(response.completion).to eq("The meaning of life is subjective and can vary from person to person.")
      end
    end

    context "with custom default_options" do
      context "with legacy model" do
        let(:logger) { double("logger") }
        let(:subject) {
          described_class.new(
            api_key: "123",
            default_options: {completion_model: "text-davinci-003"}
          )
        }
        let(:parameters) do
          {
            parameters:
            {
              n: 1,
              model: "text-davinci-003",
              prompt: "Hello World"
            }
          }
        end

        before do
          allow(Langchain).to receive(:logger).and_return(logger)
          allow(logger).to receive(:warn)
        end

        it "passes correct options to the completions method" do
          expect(subject.client).to receive(:chat).with({
            parameters: {
              n: 1,
              model: "gpt-4o-mini",
              messages: [{content: "Hello World", role: "user"}]
            }
          }).and_return(response)
          subject.complete(prompt: "Hello World")
        end
      end

      context "with new model" do
        let(:subject) {
          described_class.new(
            api_key: "123",
            default_options: {completion_model: "gpt-3.5-turbo-16k"}
          )
        }

        let(:parameters) do
          {
            parameters: {
              n: 1,
              model: "gpt-3.5-turbo",
              messages: [{content: "Hello World", role: "user"}]
            }
          }
        end

        it "passes correct options to the chat method" do
          expect(subject.client).to receive(:chat).with({
            parameters: {
              n: 1,
              model: "gpt-4o-mini",
              messages: [{content: "Hello World", role: "user"}]
            }
          }).and_return(response)
          subject.complete(prompt: "Hello World")
        end
      end
    end

    context "with prompt and parameters" do
      let(:parameters) do
        {parameters: {n: 1, model: "gpt-3.5-turbo", messages: [{content: "Hello World", role: "user"}]}}
      end

      it "returns a completion" do
        response = subject.complete(prompt: "Hello World", model: "gpt-3.5-turbo")

        expect(response.completion).to eq("The meaning of life is subjective and can vary from person to person.")
      end
    end

    context "with failed API call" do
      let(:parameters) do
        {parameters: {n: 1, model: "gpt-4o-mini", messages: [{content: "Hello World", role: "user"}]}}
      end
      let(:response) do
        {"error" => {"code" => 400, "message" => "User location is not supported for the API use.", "type" => "invalid_request_error"}}
      end

      it "raises an error" do
        expect {
          subject.complete(prompt: "Hello World")
        }.to raise_error(Langchain::LLM::ApiError, "OpenAI API error: User location is not supported for the API use.")
      end
    end
  end

  describe "#default_dimensions" do
    it "returns the default dimensions" do
      expect(subject.default_dimensions).to eq(1536)
    end

    context "when the dimensions is passed as an argument" do
      let(:subject) do
        described_class.new(api_key: "123", default_options: {
          embedding_model: "text-embedding-3-small",
          dimensions: 512
        })
      end

      it "sets the default_dimensions" do
        expect(subject.default_dimensions).to eq 512
      end
    end
  end

  describe "#chat" do
    let(:prompt) { "What is the meaning of life?" }
    let(:model) { "gpt-4o-mini" }
    let(:n) { 1 }
    let(:history) { [content: prompt, role: "user"] }
    let(:parameters) { {parameters: {n: n, messages: history, model: model}} }
    let(:answer) { "As an AI language model, I don't have feelings, but I'm functioning well. How can I assist you today?" }
    let(:answer_2) { "Alternative answer" }
    let(:choices) do
      [
        {
          "message" => {
            "role" => "assistant",
            "content" => answer
          },
          "finish_reason" => "stop",
          "index" => 0
        }
      ]
    end
    let(:response) do
      {
        "id" => "chatcmpl-9otuxUHnW84Zqu97VE1eKPmXVLAv0",
        "object" => "chat.completion",
        "created" => 1721918375,
        "model" => "gpt-4o-mini-2024-07-18",
        "usage" => {
          "prompt_tokens" => 14,
          "completion_tokens" => 25,
          "total_tokens" => 39
        },
        "choices" => choices
      }
    end

    before do
      allow(subject.client).to receive(:chat).with(parameters).and_return(response)
    end

    it "ignoresq any invalid parameters provided" do
      response = subject.chat(
        messages: [{role: "user", content: "What is the meaning of life?"}],
        top_k: 5,
        beep: :boop
      )

      expect(response).to be_a(Langchain::LLM::OpenAIResponse)
    end

    it "returns valid llm response object" do
      response = subject.chat(messages: [{role: "user", content: "What is the meaning of life?"}])

      expect(response).to be_a(Langchain::LLM::OpenAIResponse)
      expect(response.model).to eq("gpt-4o-mini-2024-07-18")
      expect(response.chat_completion).to eq("As an AI language model, I don't have feelings, but I'm functioning well. How can I assist you today?")
      expect(response.prompt_tokens).to eq(14)
      expect(response.completion_tokens).to eq(25)
      expect(response.total_tokens).to eq(39)
    end

    context "with prompt" do
      it "sends prompt within messages" do
        response = subject.chat(messages: [{role: "user", content: prompt}])

        expect(response).to be_a(Langchain::LLM::OpenAIResponse)
        expect(response.model).to eq("gpt-4o-mini-2024-07-18")
        expect(response.completions).to eq(choices)
        expect(response.chat_completion).to eq(answer)
      end
    end

    context "with messages" do
      it "sends messages" do
        response = subject.chat(messages: [{role: "user", content: prompt}])

        expect(response.chat_completion).to eq(answer)
      end
    end

    context "with context and examples" do
      let(:context) { "You are a chatbot" }
      let(:examples) do
        [
          {role: "user", content: "Hello"},
          {role: "assistant", content: "Hi. How can I assist you today?"}
        ]
      end
      let(:history) do
        [
          {role: "system", content: context},
          {role: "user", content: "Hello"},
          {role: "assistant", content: "Hi. How can I assist you today?"},
          {role: "user", content: prompt}
        ]
      end

      context "when last message is from user and prompt is present" do
        let(:messages) do
          [
            {role: "system", content: context},
            {role: "user", content: "Hello"},
            {role: "assistant", content: "Hi. How can I assist you today?"},
            {role: "user", content: "I want to ask a question"}
          ]
        end
        let(:history) do
          [
            {role: "system", content: context},
            {role: "user", content: "Hello"},
            {role: "assistant", content: "Hi. How can I assist you today?"},
            {role: "user", content: "I want to ask a question\n#{prompt}"}
          ]
        end
      end
    end

    context "with options" do
      let(:model) { "gpt-3.5-turbo-0301" }

      it "sends prompt as message and additional params and returns a response message" do
        response = subject.complete(prompt: prompt, model: model)

        expect(response.chat_completion).to eq(answer)
      end

      context "with multiple choices" do
        let(:n) { 2 }
        let(:choices) do
          [
            {
              "message" => {"role" => "assistant", "content" => answer},
              "finish_reason" => "stop",
              "index" => 0
            },
            {
              "message" => {"role" => "assistant", "content" => answer_2},
              "finish_reason" => "stop",
              "index" => 1
            }
          ]
        end

        it "returns multiple response messages" do
          response = subject.chat(messages: [content: prompt, role: "user"], model: model, n: 2)

          expect(response.completions).to eq(choices)
        end
      end
    end

    context "when streaming with a block" do
      let(:messages) { [{role: "user", content: "Tell me a joke"}] }
      let(:stream_chunks) do
        now = Time.now.to_i # Use a single timestamp for simplicity in the mock
        model_name = "gpt-4o-mini" # Define model name once
        chunk_id = "chatcmpl-stream-test" # Use a consistent ID

        [
          {"id" => chunk_id, "object" => "chat.completion.chunk", "created" => now, "model" => model_name, "choices" => [{"index" => 0, "delta" => {"role" => "assistant"}}]},
          {"id" => chunk_id, "object" => "chat.completion.chunk", "created" => now, "model" => model_name, "choices" => [{"index" => 0, "delta" => {"content" => "Why did the chicken cross the road?"}}]},
          {"id" => chunk_id, "object" => "chat.completion.chunk", "created" => now, "model" => model_name, "choices" => [{"index" => 0, "delta" => {}, "finish_reason" => "stop"}]},
          {"id" => chunk_id, "object" => "chat.completion.chunk", "created" => now, "model" => model_name, "usage" => {"prompt_tokens" => 5, "completion_tokens" => 10, "total_tokens" => 15}}
        ]
      end
      let(:collected_yielded_chunks) { [] }
      let(:streaming_block) { proc { |chunk| collected_yielded_chunks << chunk } }
      let(:expected_completion) { "Why did the chicken cross the road?" }

      before do
        allow(subject.client).to receive(:chat) do |parameters:|
          expect(parameters[:stream]).to be_a(Proc)
          expect(parameters[:stream_options]).to eq({include_usage: true})
          stream_chunks.each { |chunk| parameters[:stream].call(chunk, chunk.to_json.bytesize) }
          nil # Simulate nil return after streaming
        end
      end

      it "does not raise NoMethodError and returns correctly assembled response" do
        expect {
          response = subject.chat(messages: messages, &streaming_block)
          expect(response).to be_a(Langchain::LLM::OpenAIResponse)
          expect(response.chat_completion).to eq(expected_completion)
          expect(response.role).to eq("assistant")
          expect(response.prompt_tokens).to eq(5)
          expect(response.completion_tokens).to eq(10)
          expect(response.total_tokens).to eq(15)
        }.not_to raise_error
      end

      it "yields the processed delta chunks to the block" do
        subject.chat(messages: messages, &streaming_block)
        expected_yielded_chunks = stream_chunks.map { |c| c.dig("choices", 0) || {} }
        expect(collected_yielded_chunks).to eq(expected_yielded_chunks)
        expect(collected_yielded_chunks.map { |c| c.dig("delta", "content") }.compact.join).to eq(expected_completion)
      end
    end

    context "with streaming" do
      let(:streamed_response_chunk) do
        {
          "id" => "chatcmpl-7Hcl1sXOtsaUBKJGGhNujEIwhauaD",
          "choices" => [{"index" => 0, "delta" => {"content" => answer}, "finish_reason" => nil}]
        }
      end
      let(:token_usage) do
        {
          "usage" => {"prompt_tokens" => 10, "completion_tokens" => 11, "total_tokens" => 12}
        }
      end

      it "handles streaming responses correctly" do
        allow(subject.client).to receive(:chat) do |parameters|
          parameters[:parameters][:stream].call(streamed_response_chunk)
          parameters[:parameters][:stream].call(token_usage)
        end
        response = subject.chat(messages: [content: prompt, role: "user"]) do |chunk|
          chunk
        end
        expect(response).to be_a(Langchain::LLM::OpenAIResponse)
        expect(response.prompt_tokens).to eq(10)
        expect(response.completion_tokens).to eq(11)
        expect(response.total_tokens).to eq(12)
      end
    end

    context "with streaming and multiple choices n=2" do
      let(:answer) { "Hello how are you?" }
      let(:answer_2) { "Alternative answer" }
      let(:streamed_response_chunk) do
        {
          "id" => "chatcmpl-7Hcl1sXOtsaUBKJGGhNujEIwhauaD",
          "choices" => [{"index" => 0, "delta" => {"content" => answer}, "finish_reason" => "stop"}]
        }
      end
      let(:streamed_response_chunk_2) do
        {
          "id" => "chatcmpl-7Hcl1sXOtsaUBKJGGhNujEIwhauaD",
          "choices" => [{"index" => 1, "delta" => {"content" => answer_2}, "finish_reason" => "stop"}]
        }
      end
      let(:token_usage) do
        {
          "usage" => {"prompt_tokens" => 10, "completion_tokens" => 11, "total_tokens" => 12}
        }
      end

      it "handles streaming responses correctly" do
        allow(subject.client).to receive(:chat) do |parameters|
          parameters[:parameters][:stream].call(streamed_response_chunk)
          parameters[:parameters][:stream].call(streamed_response_chunk_2)
          parameters[:parameters][:stream].call(token_usage)
        end
        response = subject.chat(messages: [content: prompt, role: "user"], n: 2) do |chunk|
          chunk
        end
        expect(response).to be_a(Langchain::LLM::OpenAIResponse)
        expect(response.completions).to eq(
          [
            {"index" => 0, "message" => {"role" => "assistant", "content" => answer}, "finish_reason" => "stop"},
            {"index" => 1, "message" => {"role" => "assistant", "content" => answer_2}, "finish_reason" => "stop"}
          ]
        )
        expect(response.prompt_tokens).to eq(10)
        expect(response.completion_tokens).to eq(11)
        expect(response.total_tokens).to eq(12)
      end
    end

    context "with streaming and tool_calls" do
      let(:tools) do
        [{
          "type" => "function",
          "function" => {
            "name" => "foo",
            "parameters" => {
              "type" => "object",
              "properties" => {
                "value" => {
                  "type" => "string"
                }
              }
            },
            "required" => ["value"]
          }
        }]
      end
      let(:chunk_deltas) do
        [
          {"role" => "assistant", "content" => nil},
          {"tool_calls" => [{"index" => 0, "id" => "call_123456", "type" => "function", "function" => {"name" => "foo", "arguments" => ""}}]},
          {"tool_calls" => [{"index" => 0, "function" => {"arguments" => "{\"va"}}]},
          {"tool_calls" => [{"index" => 0, "function" => {"arguments" => "lue\":"}}]},
          {"tool_calls" => [{"index" => 0, "function" => {"arguments" => " \"my_s"}}]},
          {"tool_calls" => [{"index" => 0, "function" => {"arguments" => "trin"}}]},
          {"tool_calls" => [{"index" => 0, "function" => {"arguments" => "g\"}"}}]}
        ]
      end
      let(:chunks) { chunk_deltas.map { |delta| {"id" => "chatcmpl-abcdefg", "choices" => [{"index" => 0, "delta" => delta}]} } }
      let(:expected_tool_calls) do
        [
          {"id" => "call_123456", "type" => "function", "function" => {"name" => "foo", "arguments" => "{\"value\": \"my_string\"}"}}
        ]
      end

      it "handles streaming responses correctly" do
        allow(subject.client).to receive(:chat) do |parameters|
          chunks.each do |chunk|
            parameters[:parameters][:stream].call(chunk)
          end
          chunks.last
        end

        response = subject.chat(messages: [content: prompt, role: "user"], tools:) do |chunk|
          chunk
        end

        expect(response).to be_a(Langchain::LLM::OpenAIResponse)
        expect(response.raw_response.dig("choices", 0, "message", "tool_calls")).to eq(expected_tool_calls)
      end
    end

    context "with failed API call" do
      let(:response) do
        {"error" => {"code" => 400, "message" => "User location is not supported for the API use.", "type" => "invalid_request_error"}}
      end

      it "raises an error" do
        expect {
          subject.chat(messages: [content: prompt, role: "user"])
        }.to raise_error(Langchain::LLM::ApiError, "OpenAI API error: User location is not supported for the API use.")
      end
    end

    context "with tool_choice" do
      it "raises an error" do
        expect {
          subject.chat(messages: [content: prompt, role: "user"], tool_choice: "auto")
        }.to raise_error(ArgumentError, "'tool_choice' is only allowed when 'tools' are specified.")
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

  describe "tool_calls_from_choice_chunks" do
    context "without tool_calls" do
      let(:chunks) do
        [
          {"id" => "chatcmpl-abcdefg", "choices" => [{"index" => 0, "delta" => {"role" => "assistant", "content" => nil}}]},
          {"id" => "chatcmpl-abcdefg", "choices" => [{"index" => 0, "delta" => {"role" => "assistant", "content" => "Hello"}}]}
        ]
      end

      it "returns nil" do
        expect(subject.send(:tool_calls_from_choice_chunks, chunks)).to eq(nil)
      end
    end

    context "with tool_calls" do
      let(:chunk_deltas) do
        [
          {"role" => "assistant", "content" => nil},
          {"tool_calls" => [{"index" => 0, "id" => "call_123456", "type" => "function", "function" => {"name" => "foo", "arguments" => ""}}]},
          {"tool_calls" => [{"index" => 0, "function" => {"arguments" => "{\"va"}}]},
          {"tool_calls" => [{"index" => 0, "function" => {"arguments" => "lue\":"}}]},
          {"tool_calls" => [{"index" => 0, "function" => {"arguments" => " \"my_s"}}]},
          {"tool_calls" => [{"index" => 0, "function" => {"arguments" => "trin"}}]},
          {"tool_calls" => [{"index" => 0, "function" => {"arguments" => "g\"}"}}]}
        ]
      end
      let(:chunks) { chunk_deltas.map { |delta| {"id" => "chatcmpl-abcdefg", "choices" => [{"index" => 0, "delta" => delta}]} } }
      let(:expected_tool_calls) do
        [
          {"id" => "call_123456", "type" => "function", "function" => {"name" => "foo", "arguments" => "{\"value\": \"my_string\"}"}}
        ]
      end

      it "returns the tool_calls" do
        expect(subject.send(:tool_calls_from_choice_chunks, chunks)).to eq(expected_tool_calls)
      end
    end

    context "with multiple tool_calls" do
      let(:chunk_deltas) do
        [
          {"role" => "assistant", "content" => nil},
          {"tool_calls" => [{"index" => 0, "id" => "call_123", "type" => "function", "function" => {"name" => "foo", "arguments" => ""}}]},
          {"tool_calls" => [{"index" => 0, "function" => {"arguments" => "{\"va"}}]},
          {"tool_calls" => [{"index" => 0, "function" => {"arguments" => "lue\":"}}]},
          {"tool_calls" => [{"index" => 0, "function" => {"arguments" => " \"my_s"}}]},
          {"tool_calls" => [{"index" => 0, "function" => {"arguments" => "trin"}}]},
          {"tool_calls" => [{"index" => 0, "function" => {"arguments" => "g\"}"}}]},
          {"tool_calls" => [{"index" => 1, "id" => "call_456", "type" => "function", "function" => {"name" => "bar", "arguments" => ""}}]},
          {"tool_calls" => [{"index" => 1, "function" => {"arguments" => "{\"va"}}]},
          {"tool_calls" => [{"index" => 1, "function" => {"arguments" => "lue\":"}}]},
          {"tool_calls" => [{"index" => 1, "function" => {"arguments" => " \"other_s"}}]},
          {"tool_calls" => [{"index" => 1, "function" => {"arguments" => "trin"}}]},
          {"tool_calls" => [{"index" => 1, "function" => {"arguments" => "g\"}"}}]}
        ]
      end
      let(:chunks) { chunk_deltas.map { |delta| {"id" => "chatcmpl-abcdefg", "choices" => [{"index" => 0, "delta" => delta}]} } }
      let(:expected_tool_calls) do
        [
          {"id" => "call_123", "type" => "function", "function" => {"name" => "foo", "arguments" => "{\"value\": \"my_string\"}"}},
          {"id" => "call_456", "type" => "function", "function" => {"name" => "bar", "arguments" => "{\"value\": \"other_string\"}"}}
        ]
      end

      it "returns the tool_calls" do
        expect(subject.send(:tool_calls_from_choice_chunks, chunks)).to eq(expected_tool_calls)
      end
    end
  end
end
