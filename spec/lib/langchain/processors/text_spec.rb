# frozen_string_literal: true

RSpec.describe Langchain::Processors::Text do
  describe "#parse" do
    let(:file) { File.open("spec/fixtures/loaders/example.txt") }
    let(:text) { "Lorem Ipsum is simply dummy text of the printing and typesetting industry" }

    it "parses the file and returns the text" do
      expect(described_class.new.parse(file)).to include(text)
    end
  end
end
