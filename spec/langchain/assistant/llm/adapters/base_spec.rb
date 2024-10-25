# frozen_string_literal: true

RSpec.describe Langchain::Assistant::LLM::Adapters::Base do
  let(:llm) { Class.new(Langchain::Assistant::LLM::Adapters::Base) }
  subject { described_class.new(llm: llm) }

  describe "#build_chat_params" do
    it "raises NotImplementedError" do
      expect { subject.build_chat_params(tools: [], instructions: "", messages: [], tool_choice: "", parallel_tool_calls: false) }.to raise_error(NotImplementedError)
    end
  end

  describe "#extract_tool_call_args" do
    it "raises NotImplementedError" do
      expect { subject.extract_tool_call_args(tool_call: {}) }.to raise_error(NotImplementedError)
    end
  end

  describe "#build_message" do
    it "raises NotImplementedError" do
      expect { subject.build_message(role: "", content: "", image_url: "", tool_calls: [], tool_call_id: "") }.to raise_error(NotImplementedError)
    end
  end

  describe "#support_system_message?" do
    it "raises NotImplementedError" do
      expect { subject.support_system_message? }.to raise_error(NotImplementedError)
    end
  end

  describe "#tool_role" do
    it "raises NotImplementedError" do
      expect { subject.tool_role }.to raise_error(NotImplementedError)
    end
  end
end
