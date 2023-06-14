# frozen_string_literal: true

RSpec.describe Langchain::Agent::SQLQueryAgent do
  let(:db) { Langchain::Tool::Database.new(connection_string: "mock:///") }
  let(:openai) { Langchain::LLM::OpenAI.new(api_key: "123") }

  subject { described_class.new(llm: openai, db: db) }

  describe "#run" do
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
        prompt: original_prompt
      ).and_return(llm_first_response)

      allow(Langchain::Tool::Database).to receive(:execute).with(
        input: sql_string
      ).and_return(database_tool_response)

      allow(subject.llm).to receive(:complete).with(
        prompt: "Given an input question and results of a SQL query, look at the results and return the answer. Use the following format:\n\nQuestion: What is the longest length name in the users table?\n\nThe SQL query: SQLQuery: SELECT name, LENGTH(name) FROM users HAVING MAX(length);\n\nResult of the SQLQuery: []\n\nFinal answer: Final answer here\n"
      ).and_return(llm_final_response)
    end

    it "runs the agent" do
      expect(subject.run(question: question)).to eq(llm_final_response)
    end
  end

  describe "#create_prompt_for_answer" do
    it "creates a prompt" do
      expect(
        subject.send(:create_prompt_for_answer,
          question: "What is count of users in the users table?",
          sql_query: "SELECT * FROM users;",
          results: "count: 10")
      ).to eq <<~PROMPT
        Given an input question and results of a SQL query, look at the results and return the answer. Use the following format:

        Question: What is count of users in the users table?
    
        The SQL query: SELECT * FROM users;
    
        Result of the SQLQuery: count: 10
    
        Final answer: Final answer here
      PROMPT
    end
  end

  describe "#prompt_template" do
    it "returns a prompt template instance" do
      expect(subject.send(:prompt_template_answer)).to be_a(Langchain::Prompt::PromptTemplate)
    end
  end
end
