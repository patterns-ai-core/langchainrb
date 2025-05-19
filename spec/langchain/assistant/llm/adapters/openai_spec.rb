# frozen_string_literal: true

RSpec.describe Langchain::Assistant::LLM::Adapters::OpenAI do
  describe "#build_chat_params" do
    it "returns the chat parameters" do
      expect(
        subject.build_chat_params(
          messages: [{role: "user", content: "Hello"}],
          instructions: "Instructions",
          tools: [Langchain::Tool::Calculator.new],
          tool_choice: "langchain_tool_calculator__execute",
          parallel_tool_calls: false
        )
      ).to eq({
        messages: [{role: "user", content: "Hello"}],
        tools: Langchain::Tool::Calculator.function_schemas.to_openai_format,
        tool_choice: {"function" => {"name" => "langchain_tool_calculator__execute"}, "type" => "function"},
        parallel_tool_calls: false
      })
    end
  end

  describe "#support_system_message?" do
    it "returns true" do
      expect(subject.support_system_message?).to eq(true)
    end
  end

  describe "#tool_role" do
    it "returns 'tool'" do
      expect(subject.tool_role).to eq("tool")
    end
  end

  describe "#build_message" do
    context "when content is a string" do
      it "returns the OpenAI message" do
        expect(
          subject.build_message(
            role: "user",
            content: "Hello",
            image_url: "https://example.com/image.png",
            tool_calls: [{"id" => "tool_call_id", "function" => {"name" => "langchain_tool_calculator__execute", "arguments" => "{\"a\": 1, \"b\": 2}"}}],
            tool_call_id: "tool_call_id"
          )
        ).to have_attributes(role: "user", content: "Hello", image_url: "https://example.com/image.png", tool_calls: [{"id" => "tool_call_id", "function" => {"name" => "langchain_tool_calculator__execute", "arguments" => "{\"a\": 1, \"b\": 2}"}}], tool_call_id: "tool_call_id")
      end
    end

    context "when content is an array" do
      it "returns the OpenAI message" do
        expect(
          subject.build_message(
            role: "user",
            content: [{type: "text", text: "Hello"}, {type: "image_url", image_url: {url: "https://example.com/image.png"}}],
            tool_calls: [{"id" => "tool_call_id", "function" => {"name" => "langchain_tool_calculator__execute", "arguments" => "{\"a\": 1, \"b\": 2}"}}],
            tool_call_id: "tool_call_id"
          )
        ).to have_attributes(role: "user", content: "Hello", image_url: "https://example.com/image.png", tool_calls: [{"id" => "tool_call_id", "function" => {"name" => "langchain_tool_calculator__execute", "arguments" => "{\"a\": 1, \"b\": 2}"}}], tool_call_id: "tool_call_id")
      end
    end
  end
end
