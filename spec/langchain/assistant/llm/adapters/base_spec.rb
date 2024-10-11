# frozen_string_literal: true

RSpec.describe Langchain::Assistant::LLM::Adapters::Base do
  let(:adapter) { described_class.new }

  describe "#build_chat_params" do
    it "raises NotImplementedError" do
      expect { adapter.build_chat_params(tools: [], instructions: "", messages: [], tool_choice: "") }.to raise_error(NotImplementedError)
    end
  end

  describe "#extract_tool_call_args" do
    it "raises NotImplementedError" do
      expect { adapter.extract_tool_call_args(tool_call: {}) }.to raise_error(NotImplementedError)
    end
  end

  describe "#build_message" do
    it "raises NotImplementedError" do
      expect { adapter.build_message(role: "", content: "", image_url: "", tool_calls: [], tool_call_id: "") }.to raise_error(NotImplementedError)
    end
  end

  describe "#support_system_message?" do
    it "raises NotImplementedError" do
      expect { adapter.support_system_message? }.to raise_error(NotImplementedError)
    end
  end

  describe "#tool_role" do
    it "raises NotImplementedError" do
      expect { adapter.tool_role }.to raise_error(NotImplementedError)
    end
  end
end
