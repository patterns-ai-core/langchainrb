# frozen_string_literal: true

RSpec.describe Loaders::Docx do
  subject { described_class.new(file_path) }

  describe "#load" do
    let(:file_path) { Langchain.root.join("../spec/fixtures/loaders/sample.docx") }

    it "loads docx" do
      expect(subject).to be_loadable
      expect(subject.load).to include("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc ac faucibus odio.")
    end
  end

  describe "#loadable?" do
    let(:file_path) { Langchain.root.join("../spec/fixtures/loaders/cairo-unicode.pdf") }

    it "returns false" do
      expect(subject).not_to be_loadable
    end
  end
end
