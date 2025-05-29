# frozen_string_literal: true

RSpec.describe Langchain::Processors::JSONL do
  describe "#parse" do
    let(:file) { File.open("spec/fixtures/loaders/example.jsonl") }
    let(:data) do
      [
        {"name" => "Luke Skywalker", "height" => "172", "mass" => "77"},
        {"name" => "C-3PO", "height" => "167", "mass" => "75"},
        {"name" => "R2-D2", "height" => "96", "mass" => "32"},
        {"name" => "Darth Vader", "height" => "202", "mass" => "136"},
        {"name" => "Leia Organa", "height" => "150", "mass" => "49"}

      ]
    end

    it "parses the file and returns data" do
      expect(described_class.new.parse(file)).to eq(data)
    end
  end
end
