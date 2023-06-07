# frozen_string_literal: true

require "openai"
require "eqn"
require "google_search_results"

RSpec.describe "Running Chain of Thought" do
  describe "Multistep distance calculation" do
    it "should return a reasonable result" do
      search_tool = Langchain::Tool::SerpApi.new(api_key: ENV["SERPAPI_API_KEY"])
      calculator = Langchain::Tool::Calculator.new

      openai = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])

      agent = Langchain::Agent::ChainOfThoughtAgent.new(
        llm: openai,
        tools: [search_tool, calculator]
      )

      result = agent.run(question: "How many full soccer fields would be needed to cover the distance between NYC and DC in a straight line?")
      expect(result).to start_with("Approximately 2,945 soccer fields")
    end
  end
end
