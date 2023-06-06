# frozen_string_literal: true

RSpec.describe Langchain::Tool::Base do
  describe "#validate_tools!" do
    it "does not raise an error" do
      calculator_tool = Langchain::Tool::Calculator.new
      sql_db_tool = Langchain::Tool::Database.new("mock:///")
      search_tool = Langchain::Tool::SerpApi.new(api_key: "123")
      expect {
        described_class.validate_tools!(tools: [calculator_tool, sql_db_tool, search_tool])
      }.not_to raise_error
    end

    it "does raise an error" do
      # class Langchain::Tool::Magic8Ball < Langchain::Tool::Base
      # end
      # magic_8_ball = Langchain::Tool::Magic8Ball.new
      # expect {
      #   described_class.validate_tools!(tools: [magic_8_ball])
      # }.to raise_error(ArgumentError, /Tool not supported/)
    end
  end

  describe "#execute" do
    it "raises an error" do
      expect {
        described_class.execute(input: "input")
      }.to raise_error(NotImplementedError)
    end
  end
end
