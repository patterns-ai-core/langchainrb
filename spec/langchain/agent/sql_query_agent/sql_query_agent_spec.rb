# frozen_string_literal: true

RSpec.describe Langchain::Agent::SQLQueryAgent do
  let(:db) { Langchain::Tool::Database.new(connection_string: "mock:///") }
  let(:openai) { Langchain::LLM::OpenAI.new(api_key: "123") }

  subject { described_class.new(llm: openai, db: db) }

  describe "#ask" do
    let(:question) { "What is the longest length name in the users table?" }

    let(:original_prompt) {
      subject.send(:create_prompt_for_sql,
        question: question)
    }

    let(:llm_first_response) { "SQLQuery: SELECT name, LENGTH(name) FROM users HAVING MAX(length);" }
    let(:sql_string) { "SELECT name, LENGTH(name) FROM users HAVING MAX(length);" }
    let(:database_tool_response) { "name: Alessandro, length: 10" }

    let(:final_prompt) {
      subject.send(:create_prompt_for_answer,
        question: question,
        sql_query: sql_string,
        results: database_tool_response)
    }
    let(:llm_final_response) { "The longest length name is Alessandro at 10 characters." }

    before do
      allow(subject.llm).to receive(:complete).with(
        prompt: original_prompt,
        max_tokens: 3963
      ).and_return(llm_first_response)

      allow(Langchain::Tool::Database).to receive(:execute).with(
        input: sql_string
      ).and_return(database_tool_response)

      allow(subject.llm).to receive(:complete).with(
        prompt: "Given an input question and results of a SQL query, look at the results and return the answer. Use the following format:\nQuestion: What is the longest length name in the users table?\nThe SQL query: SQLQuery: SELECT name, LENGTH(name) FROM users HAVING MAX(length);\nResult of the SQLQuery: []\nFinal answer: Final answer here",
        max_tokens: 4018
      ).and_return(llm_final_response)
    end

    it "runs the agent" do
      expect(subject.ask(question: question)).to eq(llm_final_response)
    end
  end

  describe "#create_prompt_for_sql" do
    it "creates a prompt" do
      expect(
        subject.send(:create_prompt_for_sql,
          question: "What is the meaning of life?")
      ).to eq <<~PROMPT.chomp
        Given an input question, create a syntactically correct standard SQL query to run, then return the query in valid SQL.
        Never query for all the columns from a specific table, only ask for a the few relevant columns given the question.
        Pay attention to use only the column names that you can see in the schema description. Be careful to not query for columns that do not exist. Pay attention to which column is in which table. Also, qualify column names with the table name when needed.
        Only use the tables listed below.

        Use the following format:
        Question: What is the meaning of life?
        SQLQuery:
      PROMPT
    end
  end

  describe "#prompt_template" do
    it "returns a prompt template instance" do
      expect(subject.send(:prompt_template_sql)).to be_a(Langchain::Prompt::PromptTemplate)
    end
  end
end
