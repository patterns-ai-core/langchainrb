# frozen_string_literal: true

RSpec.describe Langchain::Assistant do
  it "raises an error if tools array contains non-Langchain::Tool instance(s)" do
    expect { described_class.new(tools: [Langchain::Tool::Calculator.new, "foo"]) }.to raise_error(ArgumentError)
  end

  it "raises an error if LLM class does not implement `chat()` method" do
    llm = Langchain::LLM::Cohere.new(api_key: "123")
    expect { described_class.new(llm: llm) }.to raise_error(ArgumentError)
  end

  it "raises an error if thread is not an instance of Langchain::Thread" do
    expect { described_class.new(thread: "foo") }.to raise_error(ArgumentError)
  end
end
