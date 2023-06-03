# frozen_string_literal: true

RSpec.describe Langchain::Agent::SQLQueryAgent do
  subject {
    described_class.new(
      llm: :openai,
      llm_api_key: "123",
      db_connection_string: ""
    )
  }

  describe "#ask" do
    # TODO: Still working on this, so xit tests for now
    let(:question) { "What is the longest length name in the users table?" }

    let(:original_prompt) {
      subject.send(:create_prompt_for_sql,
        question: question)
    }

    let(:llm_final_response) { "The longest name Alessandro has a length of 10" }

    before do
      allow_any_instance_of(Langchain::LLM::OpenAI).to receive(:complete).with(
        prompt: original_prompt,
        stop_sequences: ["SQL Query:"],
        max_tokens: 500
      ).and_return(llm_first_response)

      allow(Langchain::Tool::Database).to receive(:execute).with(
        input: "SELECT name, LENGTH(name) FROM users HAVING MAX(length);"
      ).and_return(database_tool_response)

      allow_any_instance_of(Langchain::LLM::OpenAI).to receive(:complete).with(
        prompt: final_prompt,
        stop_sequences: ["Answer:"],
        max_tokens: 500
      ).and_return(llm_final_response)
    end

    xit "runs the agent" do
      subject.run(question: question)
    end
  end

  describe "#prompt_template" do
    # TODO: Still working on this, so xit tests for now
    xit "returns a prompt template instance" do
      expect(subject.send(:prompt_template_sql)).to be_a(Langchain::Prompt::PromptTemplate)
    end
  end
end
