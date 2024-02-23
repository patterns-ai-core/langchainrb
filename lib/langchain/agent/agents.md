
### Agents 🤖
Agents are semi-autonomous bots that can respond to user questions and use available to them Tools to provide informed replies. They break down problems into series of steps and define Actions (and Action Inputs) along the way that are executed and fed back to them as additional information. Once an Agent decides that it has the Final Answer it responds with it.

#### ReAct Agent

Add `gem "ruby-openai"`, `gem "eqn"`, and `gem "google_search_results"` to your Gemfile

```ruby
search_tool = Langchain::Tool::GoogleSearch.new(api_key: ENV["SERPAPI_API_KEY"])
calculator = Langchain::Tool::Calculator.new

openai = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])

agent = Langchain::Agent::ReActAgent.new(
  llm: openai,
  tools: [search_tool, calculator]
)
```
```ruby
agent.run(question: "How many full soccer fields would be needed to cover the distance between NYC and DC in a straight line?")
#=> "Approximately 2,945 soccer fields would be needed to cover the distance between NYC and DC in a straight line."
```

#### SQL-Query Agent

Add `gem "sequel"` to your Gemfile

```ruby
database = Langchain::Tool::Database.new(connection_string: "postgres://user:password@localhost:5432/db_name")

agent = Langchain::Agent::SQLQueryAgent.new(llm: Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"]), db: database)
```
```ruby
agent.run(question: "How many users have a name with length greater than 5 in the users table?")
#=> "14 users have a name with length greater than 5 in the users table."
```

#### Demo
![May-12-2023 13-09-13](https://github.com/andreibondarev/langchainrb/assets/541665/6bad4cd9-976c-420f-9cf9-b85bf84f7eaf)

![May-12-2023 13-07-45](https://github.com/andreibondarev/langchainrb/assets/541665/9aacdcc7-4225-4ea0-ab96-7ee48826eb9b)

#### Available Tools 🛠️

| Name         | Description                                        | ENV Requirements                                              | Gem Requirements                          |
| ------------ | :------------------------------------------------: | :-----------------------------------------------------------: | :---------------------------------------: |
| "calculator" | Useful for getting the result of a math expression |                                                               | `gem "eqn", "~> 1.6.5"`                   |
| "database"   | Useful for querying a SQL database |                                                               | `gem "sequel", "~> 5.68.0"`                   |
| "google_search"     | A wrapper around Google Search                     | `ENV["SERPAPI_API_KEY"]` (https://serpapi.com/manage-api-key) | `gem "google_search_results", "~> 2.0.0"` |
| "weather"  | Calls Open Weather API to retrieve the current weather        |      `ENV["OPEN_WEATHER_API_KEY"]` (https://home.openweathermap.org/api_keys)               | `gem "open-weather-ruby-client", "~> 0.3.0"`    |
| "wikipedia"  | Calls Wikipedia API to retrieve the summary        |                                                               | `gem "wikipedia-client", "~> 1.17.0"`     |

