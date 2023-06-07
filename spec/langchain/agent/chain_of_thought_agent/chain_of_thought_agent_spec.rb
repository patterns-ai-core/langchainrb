# frozen_string_literal: true

RSpec.describe Langchain::Agent::ChainOfThoughtAgent do
  let(:calculator) { Langchain::Tool::Calculator.new }
  let(:search) { Langchain::Tool::SerpApi.new(api_key: "123") }
  let(:wikipedia) { Langchain::Tool::Wikipedia.new }

  let(:openai) { Langchain::LLM::OpenAI.new(api_key: "123") }

  subject { described_class.new(llm: openai, tools: [calculator, search]) }

  describe "#tools" do
    it "sets new tools" do
      expect(subject.tools.count).to eq(2)
      subject.tools = [wikipedia]
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
    let(:updated_prompt_2) { updated_prompt + llm_second_response + "\nObservation: #{calculator_tool_response}\nThought:" }
    let(:final_prompt) { updated_prompt_2 + llm_third_response + "\nObservation: #{calculator_tool_response_2}\nThought:" }

    let(:llm_first_response) { " I need to find the average temperature in Miami, Florida in May and then calculate the square root of that number.\nAction: search\nAction Input: average temperature in Miami, Florida in May" }
    let(:search_tool_response) { "May Weather in Miami Florida, United States. Daily high temperatures increase by 3°F, from 83°F to 86°F, rarely falling below 79°F or exceeding 90° ..." }
    let(:llm_second_response) { " I need to calculate the average temperature\nAction: calculator\nAction Input: (83+86+79+90)/4\n\n" }
    let(:calculator_tool_response) { "84.5" }
    let(:llm_third_response) { " I now have the average temperature and can calculate the square root\nAction: calculator\nAction Input: sqrt(84.5)\n\n" }
    let(:calculator_tool_response_2) { "9.192388155425117" }

    let(:final_answer) { "9.2" }

    let(:llm_final_response) { " I now know the final answer\nFinal Answer: #{final_answer}" }

    before do
      allow(subject.llm).to receive(:complete).with(
        prompt: original_prompt,
        stop_sequences: ["Observation:"]
      ).and_return(llm_first_response)

      allow(subject.tools[1]).to receive(:execute).with(
        input: "average temperature in Miami, Florida in May"
      ).and_return(search_tool_response)

      allow(subject.llm).to receive(:complete).with(
        prompt: updated_prompt,
        stop_sequences: ["Observation:"]
      ).and_return(llm_second_response)

      allow(subject.tools[0]).to receive(:execute).with(
        input: "(83+86+79+90)/4"
      ).and_return(calculator_tool_response)

      allow(subject.llm).to receive(:complete).with(
        prompt: updated_prompt_2,
        stop_sequences: ["Observation:"]
      ).and_return(llm_third_response)

      allow(subject.tools[0]).to receive(:execute).with(
        input: "sqrt(84.5)"
      ).and_return(calculator_tool_response_2)

      allow(subject.llm).to receive(:complete).with(
        prompt: final_prompt,
        stop_sequences: ["Observation:"]
      ).and_return(llm_final_response)
    end

    it "runs the agent" do
      expect(subject.run(question: question)).to eq(final_answer)
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
