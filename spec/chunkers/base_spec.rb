# frozen_string_literal: true

RSpec.describe Chunkers::Base do
  describe "#initialize" do
    context "when chunk_overlap is greater than chunk_size" do
      it "raises an error" do
        expect { described_class.new(chunk_size: 200, chunk_overlap: 400) }.to raise_error(ArgumentError)
      end
    end

    context "when chunk_overlap is less than or equal to chunk_size" do
      it "does not raise an error" do
        expect { described_class.new }.not_to raise_error
      end
    end
  end

  describe "#split_text" do
    it "raises NotImplementedError" do
      expect { subject.split_text("test") }.to raise_error(NotImplementedError)
    end
  end
end
