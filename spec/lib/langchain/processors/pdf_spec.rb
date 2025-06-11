# frozen_string_literal: true

RSpec.describe Langchain::Processors::PDF do
  describe "#parse" do
    let(:file) { File.open("spec/fixtures/loaders/cairo-unicode.pdf") }
    let(:text) { "UTF-8 encoded sample plain-text file" }

    it "parses the file and returns the text" do
      expect(described_class.new.parse(file)).to include(text)
    end
  end
end
