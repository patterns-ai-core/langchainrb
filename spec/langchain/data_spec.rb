# frozen_string_literal: true

RSpec.describe Langchain::Data do
  let(:source) { "spec/fixtures/loaders/example.txt" }
  let(:data) { File.read(source) }

  subject { described_class.new(data, source: source) }

  describe "#chunks" do
    it "returns an array of chunks" do
      chunks = subject.chunks
      expect(chunks[0]).to have_key(:text)
      expect(chunks[1]).to have_key(:text)
      expect(chunks[2]).to have_key(:text)
    end
  end
end
