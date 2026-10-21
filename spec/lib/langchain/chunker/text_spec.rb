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
      expect(subject.chunks).to all(be_a(Langchain::Chunk))
    end

    it "splits on the separator like Baran::CharacterTextSplitter when the pieces fit" do
      expected = Baran::CharacterTextSplitter.new(chunk_size: 1000, chunk_overlap: 200, separator: "\n\n").chunks(text).map { |chunk| chunk[:text] }

      expect(subject.chunks.map(&:text)).to eq(expected)
    end

    context "when a piece between separators is longer than chunk_size" do
      let(:line) { "word " * 50 }
      let(:text) { ([line.strip] * 40).join("\n") }

      subject { described_class.new(text, chunk_size: 1000, chunk_overlap: 200) }

      it "splits it on newlines so that no chunk is longer than chunk_size" do
        chunks = subject.chunks

        expect(chunks.length).to be > 1
        expect(chunks.map { |chunk| chunk.text.length }).to all(be <= 1000)
      end
    end

    context "when the text has no newlines" do
      let(:text) { "word " * 1000 }

      subject { described_class.new(text, chunk_size: 1000, chunk_overlap: 200) }

      it "splits it on spaces" do
        chunks = subject.chunks

        expect(chunks.length).to be > 1
        # Baran leaves the separators out when it measures a chunk
        expect(chunks.map { |chunk| chunk.text.delete(" ").length }).to all(be <= 1000)
        expect(chunks.first.text).to start_with("word word")
      end
    end
  end
end
