# frozen_string_literal: true

RSpec.describe Loaders::PDF do
  describe "#load" do
    it "loads regular text" do
      file_path = Langchain.root.join("../spec/fixtures/loaders/cairo-unicode.pdf")

      text = described_class.new(file_path).load
      expect(text).to include("UTF-8 encoded sample plain-text file")
      expect(text).to include("The ASCII compatible UTF-8 encoding used in this plain-text file")
      expect(text).to include("The Greek anthem:")
      expect(text).to include("τελευτῆς ὁντινοῦν ποιεῖσθαι λόγον.")
      expect(text).to include("Proverbs in the Amharic language")
      expect(text).to include("ወዳጅህ ማር ቢሆን ጨርስህ አትላሰው።")
    end

    it "loads ocr'd text" do
      file_path = Langchain.root.join("../spec/fixtures/loaders/clearscan-with-image-removed.pdf")

      text = described_class.new(file_path).load
      expect(text).to eq("This document was scanned and then OCRd with Adobe ClearScan")
    end
  end

  describe "initialize with chunker" do
    file_path = Langchain.root.join("../spec/fixtures/loaders/cairo-unicode.pdf")
    let(:chunker) { Chunkers::TextSplitter.new }
    subject { described_class.new(file_path, chunker: chunker) }

    it "has handle to chunker" do
      expect(subject.chunker).to be_a(Chunkers::TextSplitter)
    end
  end
end
