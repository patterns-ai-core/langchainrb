# frozen_string_literal: true

RSpec.describe Langchain::Messages::AnthropicMessage do
  it "raises an error if role is not one of allowed" do
    expect { described_class.new(role: "foo") }.to raise_error(ArgumentError)
  end

  describe "#to_hash" do
    it "returns function" do
      message = described_class.new(role: "tool_result", content: "4.0", tool_call_id: "toolu_014eSx9oBA5DMe8gZqaqcJ3H")
      expect(message.to_hash).to eq(
        {
          role: "user",
          content: [
            {
              type: "tool_result",
              tool_use_id: "toolu_014eSx9oBA5DMe8gZqaqcJ3H",
              content: "4.0"
            }
          ]
        }
      )
    end

    it "returns tool_calls" do
      message = described_class.new(
        role: "assistant",
        tool_calls: [
          {
            "type" => "tool_use",
            "id" => "toolu_01UEciZACvRZ6S4rqAwD1syH",
            "name" => "news_retriever__get_everything",
            "input" => {
              "q" => "Google I/O 2024",
              "sort_by" => "publishedAt",
              "language" => "en"
            }
          }
        ]
      )
      expect(message.to_hash).to eq(
        role: "assistant",
        content: [
          {
            "type" => "tool_use",
            "id" => "toolu_01UEciZACvRZ6S4rqAwD1syH",
            "name" => "news_retriever__get_everything",
            "input" => {
              "q" => "Google I/O 2024",
              "sort_by" => "publishedAt",
              "language" => "en"
            }
          }
        ]
      )
    end
  end
end
