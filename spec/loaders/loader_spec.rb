# frozen_string_literal: true

RSpec.describe Loader do
  describe "#load" do
    it "loads regular text" do
      files = [
        Langchain.root.join("../spec/fixtures/loaders/cairo-unicode.pdf"),
        Langchain.root.join("../spec/fixtures/loaders/clearscan-with-image-removed.pdf"),
        Langchain.root.join("../spec/fixtures/loaders/example.txt")
      ]

      loaded_contents =
        Loader
          .with(
            Loaders::PDF,
            Loaders::Text
          )
          .load(files)

      expect(loaded_contents.size).to eq(3)
      expect(loaded_contents[0]).to include("Markus Kuhn")
      expect(loaded_contents[1]).to include("Adobe ClearScan")
      expect(loaded_contents[2]).to include("Lorem Ipsum")
    end
  end
end
