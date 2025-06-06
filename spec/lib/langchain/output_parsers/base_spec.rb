# frozen_string_literal: true

RSpec.describe Langchain::OutputParsers::Base do
  describe "#parse" do
    it "must be implemented by subclasses" do
      expect { described_class.new.parse(text: "") }.to raise_error(NotImplementedError)
    end
  end

  describe "#get_format_instructions" do
    it "must be implemented by subclasses" do
      expect { described_class.new.get_format_instructions }.to raise_error(NotImplementedError)
    end
  end
end
