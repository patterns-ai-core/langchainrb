# frozen_string_literal: true

RSpec.describe LangChain::Processors::Base do
  describe "#parse" do
    it "must be implemented by subclasses" do
      expect { described_class.new.parse("") }.to raise_error(NotImplementedError)
    end
  end
end
