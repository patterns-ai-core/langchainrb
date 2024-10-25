# frozen_string_literal: true

RSpec.describe Langchain::Assistant::LLM::Adapters::Ollama do
  let(:llm) { Langchain::LLM::Ollama.new(api_key: "123") }
  subject { described_class.new(llm: llm) }

  describe "#build_chat_params" do
    it "returns the chat parameters" do
      expect(
        subject.build_chat_params(
          messages: [{role: "user", content: "Hello"}],
          instructions: "Instructions",
          tools: [Langchain::Tool::Calculator.new],
          tool_choice: "langchain_tool_calculator__execute",
          parallel_tool_calls: false
        )
      ).to eq({
        messages: [{role: "user", content: "Hello"}],
        tools: [
          {
            function: {
              description: "Evaluates a pure math expression or if equation contains non-math characters (e.g.: \"12F in Celsius\") then it uses the google search calculator to evaluate the expression",
              name: "langchain_tool_calculator__execute",
              parameters: {
                properties: {
                  input: {
                    description: "Math expression",
                    type: "string"
                  }
                },
                required: ["input"],
                type: "object"
              }
            },
            type: "function"
          }
        ]
      })
    end
  end

  describe "#support_system_message?" do
    it "returns true" do
      expect(subject.support_system_message?).to eq(true)
    end
  end

  describe "#tool_role" do
    it "returns 'tool'" do
      expect(subject.tool_role).to eq("tool")
    end
  end

  describe "#build_message" do
    it "returns an Ollama message" do
      expect(
        subject.build_message(
          role: "user",
          content: "Hello",
          image_url: "https://example.com/image.jpg"
        )
      ).to be_a(Langchain::Assistant::Messages::OllamaMessage)
    end
  end
end
