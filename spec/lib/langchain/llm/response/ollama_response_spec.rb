# frozen_string_literal: true

RSpec.describe Langchain::LLM::Response::OllamaResponse do
  subject { described_class.new(raw_response) }

  describe "embedding input usage" do
    let(:raw_response) { {"embeddings" => [[0.1, 0.2]]} }

    [0, 8].each do |count|
      it "retains a supplied input count of #{count} without a done flag" do
        raw_response["prompt_eval_count"] = count
        expect(subject.prompt_tokens).to eq(count)
        expect(subject.completion_tokens).to be_nil
        expect(subject.total_tokens).to be_nil
        expect(subject.embeddings).to eq([[0.1, 0.2]])
      end
    end

    it "keeps absent input counts unknown" do
      expect(subject.prompt_tokens).to be_nil
    end

    it "does not expose provisional counts from unfinished chat chunks" do
      raw_response.delete("embeddings")
      raw_response.merge!("done" => false, "prompt_eval_count" => 8, "eval_count" => 2)
      expect(subject.prompt_tokens).to be_nil
      expect(subject.completion_tokens).to be_nil
      expect(subject.total_tokens).to be_nil
    end
  end

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
      let(:raw_response) { JSON.parse File.read("spec/fixtures/llm/ollama/chat_with_tool_calls.json") }

      it "returns tool_calls" do
        expect(subject.tool_calls).to eq([{
          "function" => {
            "name" => "get_current_weather",
            "arguments" => {
              "format" => "celsius",
              "location" => "Paris"
            }
          }
        }])
      end
    end
  end
end
