# frozen_string_literal: true

RSpec.describe Langchain::Assistant::LLM::Adapters::Anthropic do
  let(:adapter) { described_class.new }

  describe "#support_system_message?" do
    it "returns true" do
      expect(adapter.support_system_message?).to eq(false)
    end
  end

  describe "#tool_role" do
    it "returns 'tool'" do
      expect(adapter.tool_role).to eq("tool_result")
    end
  end
end
