# frozen_string_literal: true

require "eqn"

RSpec.describe Langchain::Tool::Calculator do
  describe "#execute" do
    it "calculates the result" do
      expect(subject.execute(input: "2+2")).to eq(4)
    end

    it "rescue an error and return an explanation" do
      allow(Eqn::Calculator).to receive(:calc).and_raise(Eqn::ParseError)

      expect(
        subject.execute(input: "two plus two")
      ).to eq("\"two plus two\" is an invalid mathematical expression")
    end
  end
end
