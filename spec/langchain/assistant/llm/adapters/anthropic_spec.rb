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

  describe "#build_tool_choice" do
    it "returns the tool choice object with 'auto'" do
      expect(subject.send(:build_tool_choice, "auto", true)).to eq({disable_parallel_tool_use: false, type: "auto"})
    end

    it "returns the tool choice object with selected tool function" do
      expect(subject.send(:build_tool_choice, "langchain_tool_calculator__execute", false)).to eq({disable_parallel_tool_use: true, type: "tool", name: "langchain_tool_calculator__execute"})
    end
  end
end
