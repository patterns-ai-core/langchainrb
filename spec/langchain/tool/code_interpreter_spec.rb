# frozen_string_literal: true

RSpec.describe Tool::CodeInterpreter do
  describe "#execute" do
    it "executes the expression" do
      expect(subject.execute(input: '"hello world".reverse!')).to eq("dlrow olleh")
    end
  end
end
