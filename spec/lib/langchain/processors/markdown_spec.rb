# frozen_string_literal: true

RSpec.describe Langchain::Processors::Markdown do
  describe "#parse" do
    let(:file) { File.open("spec/fixtures/loaders/example.md") }
    let(:text) { "Lorem ipsum dolor sit amet, consectetur adipiscing elit." }

    it "parses the file and returns the text" do
      expect(described_class.new.parse(file)).to include(text)
    end
  end
end
