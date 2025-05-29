# frozen_string_literal: true

RSpec.describe Langchain::Processors::Eml do
  describe "#parse" do
    let(:file) { File.open("spec/fixtures/loaders/sample.eml") }
    let(:text) { "Lorem Ipsum.\nDolor sit amet." }

    it "parses the file and returns the text" do
      expect(described_class.new.parse(file)).to include(text)
    end
  end
end
