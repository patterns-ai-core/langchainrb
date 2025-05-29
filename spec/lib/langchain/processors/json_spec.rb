# frozen_string_literal: true

RSpec.describe Langchain::Processors::JSON do
  describe "#parse" do
    let(:file) { File.open("spec/fixtures/loaders/example.json") }
    let(:data) do
      {
        "name" => "Luke Skywalker",
        "height" => 172,
        "mass" => 77,
        "hair_color" => "blond",
        "skin_color" => "fair",
        "eye_color" => "blue",
        "birth_year" => "19BBY",
        "gender" => "male",
        "homeworld" => "https://swapi.dev/api/planets/1/",
        "species" => [
          "https://swapi.dev/api/species/1/"
        ],
        "created" => "2014-12-09T13:50:51.644000Z",
        "edited" => "2014-12-20T21:17:56.891000Z",
        "url" => "https://swapi.dev/api/people/1/"
      }
    end

    it "parses the file and returns data" do
      expect(described_class.new.parse(file)).to eq(data)
    end
  end
end
