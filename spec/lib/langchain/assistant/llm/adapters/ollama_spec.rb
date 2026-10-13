# frozen_string_literal: true

RSpec.describe Langchain::Assistant::LLM::Adapters::Ollama do
  describe "#build_chat_params" do
    it "returns the chat parameters" do
      expect(
        subject.build_chat_params(
          messages: [{role: "user", content: "Hello"}],
          instructions: "Instructions",
          tools: [Langchain::Tool::Calculator.new],
          tool_choice: nil,
          parallel_tool_calls: false
        )
      ).to eq({
        messages: [{role: "user", content: "Hello"}],
        tools: Langchain::Tool::Calculator.function_schemas.to_openai_format
      })
    end
  end

  describe "#build_chat_params with tool_choice" do
    let(:params) do
      {
        messages: [{role: "user", content: "Hello"}],
        instructions: "Instructions",
        tools: [Langchain::Tool::Calculator.new],
        parallel_tool_calls: true
      }
    end

    it "sends the tools for \"auto\" without logging a warning" do
      expect(Langchain.logger).not_to receive(:warn)

      expect(subject.build_chat_params(**params, tool_choice: "auto")).to include(:tools)
    end

    it "leaves the tools out for \"none\"" do
      expect(subject.build_chat_params(**params, tool_choice: "none")).to eq(messages: [{role: "user", content: "Hello"}])
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
    it "returns an Ollama message" do
      expect(
        subject.build_message(
          role: "user",
          content: "Hello",
          image_url: "https://example.com/image.jpg"
        )
      ).to be_a(Langchain::Assistant::Messages::OllamaMessage)
    end
  end
end
