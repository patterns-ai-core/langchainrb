# frozen_string_literal: true

require "open_router"

RSpec.describe Langchain::LLM::OpenRouter do
  let(:subject) { described_class.new(api_key: "123") }
  let(:mock_client) { instance_double(OpenRouter::Client) }

  before do
    allow(OpenRouter::Client).to receive(:new).and_return(mock_client)
  end

  describe "#initialize" do
    context "when default_options are passed" do
      let(:default_options) { {temperature: 0.7, chat_model: "mistralai/mixtral-8x7b-instruct"} }
      subject { described_class.new(api_key: "123", default_options: default_options) }

      it "sets the defaults options" do
        expect(subject.defaults[:temperature]).to eq(0.7)
        expect(subject.defaults[:chat_model]).to eq("mistralai/mixtral-8x7b-instruct")
      end

      it "gets passed to consecutive chat() call" do
        allow(mock_client).to receive(:complete)
        subject.chat(messages: [{role: "user", content: "Hello!"}])
        expect(subject.client).to have_received(:complete).with(
          [{role: "user", content: "Hello!"}],
          model: "mistralai/mixtral-8x7b-instruct",
          providers: [],
          transforms: [],
          extras: {}
        )
      end
    end
  end

  describe "#chat" do
    before do
      allow(mock_client).to receive(:complete)
    end

    it "calls the client with the requested parameters" do
      params = {
        messages: [{role: "user", content: "Hello!"}],
        temperature: 0.7,
        providers: ["anthropic", "openai"],
        transforms: ["fix-grammar"],
        extras: {max_tokens: 100}
      }

      subject.chat(params)

      expect(mock_client).to have_received(:complete).with(
        params[:messages],
        model: subject.defaults[:chat_model],
        providers: ["anthropic", "openai"],
        transforms: ["fix-grammar"],
        extras: {max_tokens: 100}
      )
    end
  end

  describe "#embed" do
    it "raises NotImplementedError" do
      expect { subject.embed(text: "test") }.to raise_error(NotImplementedError)
    end
  end

  describe "#models" do
    it "calls the client models method" do
      allow(mock_client).to receive(:models)
      subject.models
      expect(mock_client).to have_received(:models)
    end
  end
end
