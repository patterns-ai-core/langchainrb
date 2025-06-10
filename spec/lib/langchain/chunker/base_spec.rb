# frozen_string_literal: true

RSpec.describe Langchain::Chunker::Base do
  describe "#chunks" do
    it "raises NotImplementedError" do
      expect { described_class.new.chunks }.to raise_error(NotImplementedError)
    end
  end
end
