# frozen_string_literal: true

RSpec.describe Langchain::LLM::OllamaResponse do
  subject { described_class.new(raw_response) }

  describe "chat completions" do
    let(:raw_response) { JSON.parse File.read("spec/fixtures/llm/ollama/chat.json") }

    it "created_at returns correct value" do
      expect(subject.created_at).to eq(Time.parse(raw_response.dig("created_at")))
    end

    it "returns chat_completion" do
      expect(subject.chat_completion).to eq(raw_response.dig("message", "content"))
    end

    it "prompt_tokens returns correct value" do
      expect(subject.prompt_tokens).to eq(98)
    end

    it "completion_tokens returns correct value" do
      expect(subject.completion_tokens).to eq(90)
    end

    it "total_tokens return correct value" do
      expect(subject.total_tokens).to eq(188)
    end

    describe "streamed response chunk" do
      let(:raw_response) { JSON.parse File.read("spec/fixtures/llm/ollama/chat_chunk.json") }

      it "created_at returns correct value" do
        expect(subject.created_at).to eq(Time.parse(raw_response.dig("created_at")))
      end

      it "returns chat_completion" do
        expect(subject.chat_completion).to eq(raw_response.dig("message", "content"))
      end

      it "does not return prompt_tokens" do
        expect(subject.prompt_tokens).to be_nil
      end

      it "does not return completion_tokens" do
        expect(subject.completion_tokens).to be_nil
      end

      it "does not return total_tokens" do
        expect(subject.total_tokens).to be_nil
      end
    end

    describe "#tool_calls" do
      let(:raw_response) { JSON.parse File.read("spec/fixtures/llm/ollama/complete_mistral_tool_calls.json") }

      it "returns tool_calls" do
        expect(subject.tool_calls).to eq([{"name" => "weather__execute", "arguments" => {"input" => "SF"}}])
      end
    end
  end
end
