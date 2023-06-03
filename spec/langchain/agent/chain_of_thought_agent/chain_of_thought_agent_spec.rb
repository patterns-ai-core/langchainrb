# frozen_string_literal: true

RSpec.describe Langchain::Agent::ChainOfThoughtAgent do
  subject {
    described_class.new(
      llm_client: Langchain::LLM::OpenAI.new(api_key: "123"),
      tools: ["calculator", "search"]
    )
  }

  describe "#tools" do
    it "sets new tools" do
      expect(subject.tools.count).to eq(2)
      subject.tools = ["calculator"]
      expect(subject.tools.count).to eq(1)
    end
  end

  describe "#run" do
    let(:question) { "What is the square root of the average temperature in Miami, Florida in May?" }

    let(:original_prompt) {
      subject.send(:create_prompt,
        question: question,
        tools: subject.tools)
    }
    let(:updated_prompt) { original_prompt + llm_first_response + "\nObservation: #{search_tool_response}\nThought:" }
    let(:final_prompt) { updated_prompt + llm_second_response + "\nObservation: #{calculator_tool_response}\nThought:" }

    let(:llm_first_response) { " I need to find the average temperature first\nAction: search\nAction Input: \"average temperature in Miami, FL in May\"\n" }
    let(:search_tool_response) { "May Weather in Miami Florida, United States. Daily high temperatures increase by 3°F, from 83°F to 86°F, rarely falling below 79°F or exceeding 90°F." }
    let(:llm_second_response) { " I need to calculate the square root of the average temperature\nAction: calculator\nAction Input: sqrt(83+86)/2\n\n" }
    let(:calculator_tool_response) { 8.6 }
    let(:llm_final_response) { " I now know the final answer\nFinal Answer: 8.6" }

    before do
      allow_any_instance_of(Langchain::LLM::OpenAI).to receive(:complete).with(
        prompt: original_prompt,
        stop_sequences: ["Observation:"],
        max_tokens: 500
      ).and_return(llm_first_response)

      allow(Langchain::Tool::SerpApi).to receive(:execute).with(
        input: "average temperature in Miami, FL in May\""
      ).and_return(search_tool_response)

      allow_any_instance_of(Langchain::LLM::OpenAI).to receive(:complete).with(
        prompt: updated_prompt,
        stop_sequences: ["Observation:"],
        max_tokens: 500
      ).and_return(llm_second_response)

      allow(Langchain::Tool::Calculator).to receive(:execute).with(
        input: "sqrt(83+86)/2"
      ).and_return(calculator_tool_response)

      allow_any_instance_of(Langchain::LLM::OpenAI).to receive(:complete).with(
        prompt: final_prompt,
        stop_sequences: ["Observation:"],
        max_tokens: 500
      ).and_return(llm_final_response)
    end

    it "runs the agent" do
      subject.run(question: question)
    end
  end

  describe "#create_prompt" do
    before do
      allow(Date).to receive(:today).and_return(Date.parse("2023-05-12"))
    end

    it "creates a prompt" do
      expect(
        subject.send(:create_prompt,
          question: "What is the meaning of life?",
          tools: subject.tools)
      ).to eq <<~PROMPT.chomp
        Today is May 12, 2023 and you can use tools to get new information. Answer the following questions as best you can using the following tools:

        calculator: Useful for getting the result of a math expression.  The input to this tool should be a valid mathematical expression that could be executed by a simple calculator.
        search: A wrapper around Google Search.  Useful for when you need to answer questions about current events. Always one of the first options when you need to find information on internet.  Input should be a search query.

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
      expect(subject.send(:prompt_template)).to be_a(Langchain::Prompt::PromptTemplate)
    end
  end
end
