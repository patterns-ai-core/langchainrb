# frozen_string_literal: true

RSpec.describe Langchain::Data do
  let(:source) { "spec/fixtures/loaders/example.txt" }
  let(:data) { File.read(source) }

  subject { described_class.new(data, source: source) }

  describe "#chunks" do
    it "returns an array of chunks" do
      chunks = subject.chunks
      split_data = data.split("\n\n")

      expect(chunks).to all(be_a(Langchain::Chunk))
      expect(chunks[0].text).to eq(split_data[0])
      expect(chunks[1].text).to eq(split_data[1])
      expect(chunks[2].text).to eq(split_data[2])
    end
  end
end
