# frozen_string_literal: true

RSpec.describe Agent::ChainOfThoughtAgent do
  subject {
    described_class.new(
      llm: :openai,
      llm_api_key: "123",
      tools: ["calculator", "search"]
    )
  }

  describe "#tools=" do
    it "sets new tools" do
      expect(subject.tools.count).to eq(2)
      subject.tools = ["calculator"]
      expect(subject.tools.count).to eq(1)
    end
  end

  describe "#create_prompt" do
    it "creates a prompt" do
      expect(
        subject.send(:create_prompt,
          question: "What is the meaning of life?",
          tools: subject.tools
        )
      ).to eq <<~PROMPT.chomp
      Today is {date} and you can use tools to get new information. Answer the following questions as best you can using the following tools:
      
      calculator: Useful for getting the result of a math expression. The input to this tool should be a valid mathematical expression that could be executed by a simple calculator.
      search: A wrapper around Google Search. Useful for when you need to answer questions about current events. Always one of the first options when you need to find information on internet. Input should be a search query.
      
      Use the following format:
      
      Question: the input question you must answer
      Thought: you should always think about what to do
      Action: the action to take, should be one of [calculator, search]
      Action Input: the input to the action
      Observation: the result of the action
      ... (this Thought/Action/Action Input/Observation can repeat N times)
      Thought: I now know the final answer
      Final Answer: the final answer to the original input question
      
      Begin!
      
      Question: What is the meaning of life?
      Thought:
      PROMPT
    end
  end

  describe "#prompt_template" do
    it "returns a prompt template instance" do
      expect(subject.send(:prompt_template)).to be_a(Prompt::PromptTemplate)
    end
  end
end