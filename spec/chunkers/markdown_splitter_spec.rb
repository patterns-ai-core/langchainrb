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
        And more text from section 2.
        blah blah blah

        # Section 3
        This is sample text from section 3.
        - a
        - b
        - c

        # Section 4

        Not in section 4.
      MARKDOWN

      split_md_text = subject.split_text(markdown_text)

      expect(split_md_text.size).to eq(5)
    end
  end
end
