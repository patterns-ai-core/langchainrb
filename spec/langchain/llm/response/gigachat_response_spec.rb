# frozen_string_literal: true

RSpec.describe Langchain::LLM::GigachatResponse do
  subject { described_class.new(raw_response) }

  describe "chat completions" do
    let(:raw_response) { JSON.parse File.read("spec/fixtures/llm/gigachat/chat.json") }

    it "created_at returns correct value" do
      expect(subject.created_at).to eq(Time.at(raw_response.dig("created")))
    end

    it "returns chat_completion" do
      expect(subject.chat_completion).to eq(raw_response.dig("choices", 0, "message", "content"))
    end

    it "prompt_tokens returns correct value" do
      expect(subject.prompt_tokens).to eq(18)
    end

    it "completion_tokens returns correct value" do
      expect(subject.completion_tokens).to eq(68)
    end

    it "total_tokens return correct value" do
      expect(subject.total_tokens).to eq(86)
    end

    describe "streamed response chunk" do
      let(:raw_response) { JSON.parse File.read("spec/fixtures/llm/gigachat/chat_chunk.json") }

      it "created_at returns correct value" do
        expect(subject.created_at).to eq(Time.at(raw_response.dig("created")))
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
      let(:raw_response) { JSON.parse File.read("spec/fixtures/llm/gigachat/chat_with_function_call.json") }

      it "returns tool_calls" do
        expect(subject.tool_calls).to eq({
          "arguments" => {"format" => "celsius", "location" => "Москва"}, "name" => "weather_forecast"
        })
      end
    end
  end
end
