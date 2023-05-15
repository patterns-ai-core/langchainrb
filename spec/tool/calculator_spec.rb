# frozen_string_literal: true

RSpec.describe Tool::Calculator do
  describe "#execute" do
    it "calculates the result" do
      expect(described_class.execute(input: "2+2")).to eq(4)
    end

    it "calls Serp API when eqn throws an error" do
      allow(Eqn::Calculator).to receive(:calc).and_raise(Eqn::ParseError)

      expect(Tool::SerpApi).to receive(:execute_search).with(input: "2+2").and_return({answer_box: {to: 4}})

      described_class.execute(input: "2+2")
    end
  end
end
