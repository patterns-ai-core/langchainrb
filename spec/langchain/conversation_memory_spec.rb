# frozen_string_literal: true

RSpec.describe Langchain::ConversationMemory do
  let(:llm) { Langchain::LLM::OpenAI.new(api_key: "123") }

  describe "passing the functions param" do
    let(:functions) {
      {
        functions: [
          {
            name: "get_current_weather",
            description: "Get the current weather in a given location",
            parameters: {
              type: :object,
              properties: {
                location: {
                  type: :string,
                  description: "The city and state, e.g. San Francisco, CA"
                },
                unit: {
                  type: "string",
                  enum: %w[celsius fahrenheit]
                }
              },
              required: ["location"]
            }
          }
        ]
      }
    }

    it "sets the functions" do
      subject = described_class.new(llm: llm, functions: functions)

      expect(subject.functions).to eq(functions)
    end

    it "throws an error" do
      llm = Langchain::LLM::Cohere.new(api_key: "123")

      expect {
        described_class.new(llm: llm, functions: functions)
      }.to raise_error(ArgumentError)
    end
  end
end
