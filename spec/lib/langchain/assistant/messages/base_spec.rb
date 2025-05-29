# frozen_string_literal: true

RSpec.describe Langchain::Assistant::Messages::Base do
  describe "tool?" do
    it "raises an error" do
      expect { described_class.new.tool? }.to raise_error(NotImplementedError)
    end
  end

  describe "system?" do
    it "raises an error" do
      expect { described_class.new.system? }.to raise_error(NotImplementedError)
    end
  end

  describe "llm?" do
    it "raises an error" do
      expect { described_class.new.llm? }.to raise_error(NotImplementedError)
    end
  end
end
