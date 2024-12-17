# frozen_string_literal: true

RSpec.describe Langchain::Assistant::Messages::AnthropicMessage do
  it "raises an error if role is not one of allowed" do
    expect { described_class.new(role: "foo") }.to raise_error(ArgumentError)
  end

  describe "#to_hash" do
    context "when role is assistant" do
      let(:role) { "assistant" }

      it "returns assistant_hash" do
        message = described_class.new(role: role, content: "Hello, how can I help you?")
        expect(message).to receive(:assistant_hash).and_call_original
        expect(message.to_hash).to eq(
          role: role,
          content: [
            {
              type: "text",
              text: "Hello, how can I help you?"
            }
          ]
        )
      end

      it "returns assistant_hash with tool_calls" do
        message = described_class.new(
          role: role,
          content: "Okay, let's fetch the news",
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
          role: role,
          content: [
            {
              type: "text",
              text: "Okay, let's fetch the news"
            },
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

      it "returns assistant_hash with tool_calls without content" do
        message = described_class.new(
          role: role,
          content: nil,
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
          role: role,
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

    context "when role is tool_result" do
      let(:message) { described_class.new(role: "tool_result", content: "4.0", tool_call_id: "toolu_014eSx9oBA5DMe8gZqaqcJ3H") }

      it "returns tool_hash" do
        expect(message).to receive(:tool_hash).and_call_original
        expect(message.to_hash).to eq(
          {
            role: "user",
            content: [
              {
                type: "tool_result",
                tool_use_id: "toolu_014eSx9oBA5DMe8gZqaqcJ3H",
                content: [
                  {
                    type: "text",
                    text: "4.0"
                  }
                ]
              }
            ]
          }
        )
      end

      it "returns tool_hash with image_url" do
        message = described_class.new(role: "tool_result", image_url: "https://example.com/image.jpg")
        allow(message).to receive(:image).and_return(double(base64: "base64_data", mime_type: "image/jpeg"))

        expect(message.to_hash).to eq(
          role: "user",
          content: [
            {
              type: "tool_result",
              tool_use_id: nil,
              content: [
                {
                  type: "image",
                  source: {
                    type: "base64",
                    data: "base64_data",
                    media_type: "image/jpeg"
                  }
                }
              ]
            }
          ]
        )
      end
    end

    context "when role is user" do
      let(:role) { "user" }

      it "returns user_hash" do
        message = described_class.new(role: role, content: "Hello, how can I help you?")
        expect(message).to receive(:user_hash).and_call_original
        expect(message.to_hash).to eq(
          role: role,
          content: [
            {
              type: "text",
              text: "Hello, how can I help you?"
            }
          ]
        )
      end

      it "returns user_hash with image_url" do
        message = described_class.new(role: role, image_url: "https://example.com/image.jpg")
        allow(message).to receive(:image).and_return(double(base64: "base64_data", mime_type: "image/jpeg"))

        expect(message.to_hash).to eq(
          role: role,
          content: [
            {
              type: "image",
              source: {
                type: "base64",
                data: "base64_data",
                media_type: "image/jpeg"
              }
            }
          ]
        )
      end
    end
  end
end
