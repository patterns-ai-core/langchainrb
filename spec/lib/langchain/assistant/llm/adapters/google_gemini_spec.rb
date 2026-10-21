# frozen_string_literal: true

RSpec.describe Langchain::Assistant::LLM::Adapters::GoogleGemini do
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
        tools: Langchain::Tool::Calculator.function_schemas.to_google_gemini_format,
        tool_choice: {function_calling_config: {allowed_function_names: ["langchain_tool_calculator__execute"], mode: "any"}},
        system: "Instructions"
      })
    end
  end

  describe "#build_message" do
    it "keeps the image_url" do
      message = subject.build_message(role: "user", content: "Describe this image.", image_url: "gs://bucket/cat.png")

      expect(message.image_url).to eq("gs://bucket/cat.png")
      expect(message.to_hash[:parts].last).to eq({fileData: {mimeType: "image/png", fileUri: "gs://bucket/cat.png"}})
    end
  end

  describe "#support_system_message?" do
    it "returns true" do
      expect(subject.support_system_message?).to eq(false)
    end
  end

  describe "#tool_role" do
    it "returns 'tool'" do
      expect(subject.tool_role).to eq("function")
    end
  end
end
