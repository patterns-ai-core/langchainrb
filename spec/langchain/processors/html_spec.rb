# frozen_string_literal: true

RSpec.describe Langchain::Processors::HTML do
  describe "#parse" do
    let(:file) { File.open("spec/fixtures/loaders/example.html") }
    let(:text) { "Lorem Ipsum\n\nDolor sit amet." }

    it "parses the file and returns the text" do
      expect(described_class.new.parse(file)).to include(text)
    end
  end
end
