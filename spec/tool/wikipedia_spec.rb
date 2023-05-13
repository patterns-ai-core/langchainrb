# frozen_string_literal: true

RSpec.describe Tool::Wikipedia do
  describe "#execute" do
    before do
      allow(Wikipedia).to receive(:find)
        .with("Ruby")
        .and_return(
          double(summary: "Ruby is an interpreted, high-level, general-purpose programming language.")  
        )
    end

    it "returns a wikipedia summary" do
      expect(described_class.execute(input: "Ruby")).to include("Ruby is an interpreted, high-level, general-purpose programming language.")
    end
  end
end
