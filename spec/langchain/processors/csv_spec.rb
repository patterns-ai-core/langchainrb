# frozen_string_literal: true

RSpec.describe Langchain::Processors::CSV do
  describe "#parse" do
    let(:file) { File.open("spec/fixtures/loaders/example.csv") }

    context "without chunk_mode options" do
      let(:data) {
        <<~EXPECTED_OUTPUT.chomp
          Username,Identifier,First name,Last name

          booker12,9012,Rachel,Booker

          grey07,2070,Laura,Grey

          johnson81,4081,Craig,Johnson

          jenkins46,9346,Mary,Jenkins

          smith79,5079,Jamie,Smith
        EXPECTED_OUTPUT
      }

      it "parses the file and returns the text" do
        expect(described_class.new.parse(file)).to eq(data)
      end
    end

    context "with chunk_mode options" do
      context "when chunking rows" do
        let(:data) {
          <<~EXPECTED_OUTPUT.chomp
            Username,Identifier,First name,Last name
  
            booker12,9012,Rachel,Booker
  
            grey07,2070,Laura,Grey
  
            johnson81,4081,Craig,Johnson
  
            jenkins46,9346,Mary,Jenkins
  
            smith79,5079,Jamie,Smith
          EXPECTED_OUTPUT
        }

        it "parses the file and returns the text" do
          expect(described_class.new({chunk_mode: described_class::CHUNK_MODE[:row]}).parse(file)).to eq(data)
        end
      end

      context "when chunking file" do
        let(:data) {
          <<~EXPECTED_OUTPUT
            Username,Identifier,First name,Last name
            booker12,9012,Rachel,Booker
            grey07,2070,Laura,Grey
            johnson81,4081,Craig,Johnson
            jenkins46,9346,Mary,Jenkins
            smith79,5079,Jamie,Smith
          EXPECTED_OUTPUT
        }

        it "parses the file and returns the text" do
          expect(described_class.new({chunk_mode: described_class::CHUNK_MODE[:file]}).parse(file)).to eq(data)
        end
      end

      context "with an invalid chunk mode" do
        it "raises an error" do
          expect { described_class.new({chunk_mode: "unknown"}).parse(file) }.to raise_error(described_class::InvalidChunkMode)
        end
      end
    end
  end
end
