# frozen_string_literal: true

RSpec.describe Langchain::Processors::Docx do
  describe "#parse" do
    let(:file) { File.open("spec/fixtures/loaders/sample.docx") }
    let(:text) { "Lorem ipsum dolor sit amet, consectetur adipiscing elit" }

    it "parses the file and returns the text" do
      expect(described_class.new.parse(file)).to include(text)
    end
  end
end
