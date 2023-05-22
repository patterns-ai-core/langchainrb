# frozen_string_literal: true

RSpec.describe Chunkers::TextSplitter do
  describe "#split_text" do
    it "works with single delimeter" do
      text = <<~TEXT
        Section 1
        This is sample text from section 1.

        Section 2
        This is sample text from section 2.

        Section 3
        This is sample text from section 3.
      TEXT

      split_text = described_class.new(delimeter: "\n\n", chunk_size: 200).split_text(text)

      expect(split_text.size).to eq(3)

      expect(split_text[0]).to start_with("Section 1")
      expect(split_text[1]).to start_with("Section 2")
      expect(split_text[2]).to start_with("Section 3")
    end

    describe "multiple delimeter parsing" do
      it { expect(described_class.new(delimeter: ["\n\n", ";\n"]).delimeter).to eq(/\n\n|;\n/) }
      it { expect(described_class.new(delimeter: ["\n"]).delimeter).to eq(/\n/) }
      it { expect(described_class.new(delimeter: ["?"]).delimeter).to eq(/\?/) }
    end

    it "works with multiple delimeters" do
      text = <<~TEXT
        Section 1;
        This is sample text from section 1.

        Section 2;
        This is sample text from section 2.

        Section 3;
        This is sample text from section 3.
      TEXT

      split_text = described_class.new(delimeter: ["\n\n", ";\n"], chunk_size: 200).split_text(text)

      expect(split_text.size).to eq(6)

      expect(split_text[0]).to start_with("Section 1")
      expect(split_text[1]).to start_with("This is sample text from section 1.")
      expect(split_text[2]).to start_with("Section 2")
      expect(split_text[3]).to start_with("This is sample text from section 2.")
      expect(split_text[4]).to start_with("Section 3")
      expect(split_text[5]).to start_with("This is sample text from section 3.")
    end

    it "works with delimeter function" do
      text = <<~TEXT.strip
        Section 1: This is sample text from section 1.
        And more text from section 1.

        Section 2: This is sample text from section 2.
        And more text from section 2.

        blah blah blah

        Section 3: This is sample text from section 3.
        And more text from section 3.
      TEXT

      function = ->(line) { line.start_with?(/Section \d:/) }
      split_text = described_class.new(delimeter: "\n\n", delimeter_function: function).split_text(text)

      expect(split_text.size).to eq(3)
      expect(split_text[0]).to start_with("Section 1:")
      expect(split_text[0]).to end_with("from section 1.")

      expect(split_text[1]).to start_with("Section 2:")
      expect(split_text[1]).to end_with("blah blah blah")

      expect(split_text[2]).to start_with("Section 3:")
      expect(split_text[2]).to end_with("from section 3.")
    end
  end
end
