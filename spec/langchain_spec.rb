# frozen_string_literal: true

RSpec.describe Langchain do
  it "has a version number" do
    expect(Langchain::VERSION).not_to be nil
  end

  describe "config" do
    it "is of correct class" do
      expect(Langchain.config).to be_a(Langchain::Config)
    end

    it "can be configured" do
      described_class.configure do |config|
        config.vectorsearch = {a: 1}
      end

      expect(Langchain.config.vectorsearch).to eq({a: 1})
    end
  end
end
