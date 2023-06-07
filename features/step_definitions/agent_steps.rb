Given("I want to know a difficult distance calculation") do
  search_tool = Langchain::Tool::SerpApi.new(api_key: ENV["SERPAPI_API_KEY"])
  calculator = Langchain::Tool::Calculator.new

  openai = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])

  @agent = Langchain::Agent::ChainOfThoughtAgent.new(
    llm: openai,
    tools: [search_tool, calculator]
  )
end

When("I ask {string}") do |string|
  @result = @agent.run(question: string.to_s)
end

Then("I should be told something like {string}") do |string|
  # TODO: This is a bad test, but it's a start
  expect(@result).to start_with(string)
end
