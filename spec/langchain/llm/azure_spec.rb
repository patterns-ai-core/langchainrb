# frozen_string_literal: true

require "openai"

RSpec.describe Langchain::LLM::Azure do
  let(:subject) do
    described_class.new(
      api_key: "123",
      embedding_deployment_url: "http://localhost:1234/deployments/embedding",
      chat_deployment_url: "http://localhost:1234/deployments/chat"
    )
  end

  describe "#initialize" do
    context "when only required options are passed" do
      it "initializes the client without any errors" do
        expect { subject }.not_to raise_error
      end
    end

    context "when llm_options are passed" do
      let(:subject) do
        described_class.new(
          api_key: "123",
          llm_options: {api_type: :azure},
          embedding_deployment_url: "http://localhost:1234/deployments/embedding",
          chat_deployment_url: "http://localhost:1234/deployments/chat"
        )
      end

      it "initializes the client without any errors" do
        expect { subject }.not_to raise_error
      end

      it "passes correct options to the client" do
        # openai-ruby sets global configuration options here: https://github.com/alexrudall/ruby-openai/blob/main/lib/openai/client.rb
        result = subject
        expect(result.embed_client.api_type).to eq(:azure)
        expect(result.chat_client.api_type).to eq(:azure)
      end
    end

    context "with custom default_options" do
      let(:subject) do
        described_class.new(
          api_key: "123",
          llm_options: {api_type: :azure},
          default_options: {
            completion_model_name: "gpt-4o-mini",
            n: 2,
            temperature: 0.5
          }
        )
      end

      it "updates chat_parameters with correct arguments" do
        expect(subject.chat_parameters[:model]).to eq("gpt-4o-mini")
        expect(subject.chat_parameters[:n]).to eq(2)
        expect(subject.chat_parameters[:temperature]).to eq(0.5)
      end
    end

    xcontext "when default_options are passed" do
      let(:default_options) { {response_format: {type: "json_object"}} }

      subject {
        described_class.new(
          api_key: "123",
          embedding_deployment_url: "http://localhost:1234/deployments/embedding",
          chat_deployment_url: "http://localhost:1234/deployments/chat",
          default_options: default_options
        )
      }

      it "sets the defaults options" do
        expect(subject.defaults[:response_format]).to eq(type: "json_object")
      end

      it "get passed to consecutive chat() call" do
        subject
        expect(subject.client).to receive(:chat).with(parameters: hash_including({response_format: {type: "json_object"}})).and_return({})
        subject.chat(messages: [{role: "user", content: "Hello json!"}])
      end
    end
  end
end
