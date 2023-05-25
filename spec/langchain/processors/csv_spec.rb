# frozen_string_literal: true

RSpec.describe Langchain::Processors::CSV do
  describe "#parse" do
    let(:file) { File.open("spec/fixtures/loaders/example.csv") }
    let(:data) {
      [
        ["Username","Identifier","First name","Last name"],
        ["booker12","9012","Rachel","Booker"],
        ["grey07","2070","Laura","Grey"],
        ["johnson81","4081","Craig","Johnson"],
        ["jenkins46","9346","Mary","Jenkins"],
        ["smith79","5079","Jamie","Smith"],
      ]
     }

    it "parses the file and returns the text" do
      expect(described_class.new.parse(file)).to eq(data)
    end
  end
end
