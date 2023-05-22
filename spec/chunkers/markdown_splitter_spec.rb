# frozen_string_literal: true

RSpec.describe Chunkers::MarkdownSplitter do
  describe "#split_text" do
    it "works" do
      markdown_text = <<~MARKDOWN.strip
        # Section 1
        This is sample text from section 1.
        And more text from section 1.

        # Section 2
        This is sample text from section 2.

        # Section 3
        This is sample text from section 3.
        - a
        - b
        - c

        # Section 4

        Not in section 4.
      MARKDOWN

      split_md_text = subject.split_text(markdown_text)

      expect(split_md_text.size).to eq(12)

      expect(split_md_text[0]).to start_with("# Section 1")
      expect(split_md_text[1]).to start_with("This is sample text from section 1.")
      expect(split_md_text[2]).to start_with("And more text from section 1.")
      expect(split_md_text[3]).to start_with("# Section 2")
      expect(split_md_text[4]).to start_with("This is sample text from section 2.")
      expect(split_md_text[5]).to start_with("# Section 3")
      expect(split_md_text[6]).to start_with("This is sample text from section 3.")
      expect(split_md_text[7]).to start_with("- a")
      expect(split_md_text[8]).to start_with("- b")
      expect(split_md_text[9]).to start_with("- c")
      expect(split_md_text[10]).to start_with("# Section 4")
      expect(split_md_text[11]).to start_with("Not in section 4.")
    end
  end
end
