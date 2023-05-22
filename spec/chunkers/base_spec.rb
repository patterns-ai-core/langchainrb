# frozen_string_literal: true

RSpec.describe Chunkers::Base do
  describe "#initialize" do
    context "when chunk_overlap is greater than or equal chunk_size" do
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

  describe "#chunked" do
    it "splits bigger chunks" do
      text = "a" * 1000
      subject = described_class.new(chunk_size: 100)

      def subject.split_text(text)
        Array.new(1, text)
      end

      expect(subject.chunked(text).size).to eq(10)
    end

    xit "splits with overlap" do
      text = "this" + "that" + "thee"
      subject = described_class.new(chunk_size: 3, chunk_overlap: 2)

      def subject.split_text(text)
        Array.new(1, text)
      end

      chunked_overlapped_text = subject.chunked(text)
      expect(chunked_overlapped_text[0]).to eq("thi")
      expect(chunked_overlapped_text[1]).to eq("his")
      expect(chunked_overlapped_text[2]).to eq("ist")
      expect(chunked_overlapped_text[2]).to eq("sth")
      expect(chunked_overlapped_text[2]).to eq("tha")
      expect(chunked_overlapped_text[2]).to eq("hat")
      expect(chunked_overlapped_text[2]).to eq("att")
      expect(chunked_overlapped_text[2]).to eq("tte")
      expect(chunked_overlapped_text[2]).to eq("tee")
      expect(chunked_overlapped_text[2]).to eq("ee")
    end
  end
end
