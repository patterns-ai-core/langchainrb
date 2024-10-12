# frozen_string_literal: true

RSpec.describe Langchain::Assistant::LLM::Adapters::Anthropic do
  subject { described_class.new }

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
        tools: Langchain::Tool::Calculator.function_schemas.to_anthropic_format,
        tool_choice: {disable_parallel_tool_use: true, name: "langchain_tool_calculator__execute", type: "tool"},
        system: "Instructions"
      })
    end
  end

  describe "#support_system_message?" do
    it "returns true" do
      expect(subject.support_system_message?).to eq(false)
    end
  end

  describe "#tool_role" do
    it "returns 'tool'" do
      expect(subject.tool_role).to eq("tool_result")
    end
  end
end
