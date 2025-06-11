# frozen_string_literal: true

RSpec.describe Langchain::Assistant::LLM::Adapters::AwsBedrockAnthropic do
  describe "#build_tool_choice" do
    it "returns the tool choice object with 'auto'" do
      expect(subject.send(:build_tool_choice, "auto", false)).to eq({type: "auto"})
    end

    it "returns the tool choice object with selected tool function" do
      expect(subject.send(:build_tool_choice, "langchain_tool_calculator__execute", false)).to eq({type: "tool", name: "langchain_tool_calculator__execute"})
    end
  end
end
