Given('I want to know a difficult distance calculation') do
    Langchain.logger.level = :info
    search_tool = Langchain::Tool::SerpApi.new(api_key: ENV["SERPAPI_API_KEY"])
    calculator = Langchain::Tool::Calculator.new

    openai = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])

    @agent = Langchain::Agent::ChainOfThoughtAgent.new(
      llm: openai,
      tools: [search_tool, calculator]
    )
end
  
When('I ask {string}') do |string|
    @result = @agent.run(question: "#{string}")
end
  
Then('I should be told something like {string}') do |string|
    expect(@result).to start_with(string)
end