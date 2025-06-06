# frozen_string_literal: true

require "eqn"

RSpec.describe Langchain::Tool::Calculator do
  describe "#execute" do
    it "calculates the result" do
      response = subject.execute(input: "2+2")
      expect(response).to be_a(Langchain::ToolResponse)
      expect(response.content).to eq(4)
    end

    it "rescue an error and return an explanation" do
      allow(Eqn::Calculator).to receive(:calc).and_raise(Eqn::ParseError)

      response = subject.execute(input: "two plus two")
      expect(response).to be_a(Langchain::ToolResponse)
      expect(response.content).to eq("\"two plus two\" is an invalid mathematical expression")
    end
  end
end
