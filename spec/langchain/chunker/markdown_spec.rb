# frozen_string_literal: true

RSpec.describe Langchain::Chunker::Markdown do
  let(:source) { "spec/fixtures/loaders/example.md" }
  let(:markdown) { File.read(source) }

  subject {
    described_class.new(markdown,
      chunk_size: 1000,
      chunk_overlap: 200)
  }

  describe "#chunks" do
    it "returns an array of chunks" do
      expect(Baran::MarkdownSplitter).to receive(:new).with(
        chunk_size: 1000,
        chunk_overlap: 200
      ).and_call_original

      allow_any_instance_of(Baran::MarkdownSplitter).to receive(:chunks)
        .with(markdown)
        .and_call_original

      subject.chunks
    end
  end
end
