# frozen_string_literal: true

RSpec.describe Langchain::Processors::Xls do
  describe "#parse" do
    let(:file) { File.open("spec/fixtures/loaders/sample.xls") }
    let(:data) {
      [
        ["Username", "Identifier", "First name", "Last name"],
        ["booker12", "9012", "Rachel", "Booker"],
        ["grey07", "2070", "Laura", "Grey"],
        ["johnson81", "4081", "Craig", "Johnson"],
        ["jenkins46", "9346", "Mary", "Jenkins"],
        ["smith79", "5079", "Jamie", "Smith"],

        ["FirstName", "LastName", "Street", "Town", "ZIP"],
        ["John", "Doe", "120 jefferson st.", "Riverside", "8075"],
        ["Jack", "McGinnis", "220 hobo Av.", "Phila", "9119"],
        ['John "Da Man"', "Repici", "120 Jefferson St.", "Riverside", "8075"],
        ["Stephen", "Tyler", '7452 Terrace "At the Plaza" road', "SomeTown", "91234"],
        ["", "Blankman", "", "SomeTown", "298"],
        ['Joan "the bone", Anne', "Jet", "9th, at Terrace plc", "Desert City", "123"]
      ]
    }

    it "parses the file and returns the text" do
      expect(described_class.new.parse(file)).to eq(data)
    end
  end
end
