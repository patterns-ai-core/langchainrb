# frozen_string_literal: true

RSpec.describe Langchain::Chunker::Sentence do
  let(:source) { "spec/fixtures/loaders/the_alchemist.txt" }
  let(:text) { File.read(source) }

  subject { described_class.new(text) }

  describe "#chunks" do
    it "returns an array of chunks" do
      expect(subject.chunks.count).to eq(25)
    end
  end
end
