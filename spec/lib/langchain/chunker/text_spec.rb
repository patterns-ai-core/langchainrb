# frozen_string_literal: true

RSpec.describe Langchain::Chunker::Text do
  let(:source) { "spec/fixtures/loaders/example.txt" }
  let(:text) { File.read(source) }

  subject {
    described_class.new(text,
      chunk_size: 1000,
      chunk_overlap: 200,
      separator: "\n\n")
  }

  describe "#chunks" do
    it "returns an array of chunks" do
      expect(Baran::CharacterTextSplitter).to receive(:new).with(
        chunk_size: 1000,
        chunk_overlap: 200,
        separator: "\n\n"
      ).and_call_original

      allow_any_instance_of(Baran::CharacterTextSplitter).to receive(:chunks)
        .with(text)
        .and_call_original

      subject.chunks
    end
  end
end
