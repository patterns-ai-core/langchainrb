# frozen_string_literal: true

RSpec.describe Langchain::Tool::Base do
  describe "#validate_tools!" do
    it "raises an error" do
      expect {
        described_class.validate_tools!(tools: ["calculator", "search"])
      }.not_to raise_error
    end

    it "does not raise an error" do
      expect {
        described_class.validate_tools!(tools: ["magic_8_ball"])
      }.to raise_error(ArgumentError, /Unrecognized Tools/)
    end
  end
end
