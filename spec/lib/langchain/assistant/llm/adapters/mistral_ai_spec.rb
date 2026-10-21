# frozen_string_literal: true

RSpec.describe Langchain::Assistant::LLM::Adapters::MistralAI do
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
        tools: Langchain::Tool::Calculator.function_schemas.to_openai_format,
        tool_choice: {"function" => {"name" => "langchain_tool_calculator__execute"}, "type" => "function"},
        parallel_tool_calls: false
      })
    end

    it "sends parallel_tool_calls" do
      [true, false].each do |parallel_tool_calls|
        params = subject.build_chat_params(
          messages: [{role: "user", content: "Hello"}],
          instructions: "Instructions",
          tools: [Langchain::Tool::Calculator.new],
          tool_choice: "auto",
          parallel_tool_calls: parallel_tool_calls
        )

        expect(params[:parallel_tool_calls]).to eq(parallel_tool_calls)
      end
    end

    it "leaves out the tool parameters without tools" do
      params = subject.build_chat_params(
        messages: [{role: "user", content: "Hello"}],
        instructions: "Instructions",
        tools: [],
        tool_choice: "auto",
        parallel_tool_calls: true
      )

      expect(params).to eq({messages: [{role: "user", content: "Hello"}]})
    end
    it "sends \"auto\" and \"none\" as strings, not as a function name" do
      ["auto", "none"].each do |choice|
        params = subject.build_chat_params(
          messages: [{role: "user", content: "Hello"}],
          instructions: "Instructions",
          tools: [Langchain::Tool::Calculator.new],
          tool_choice: choice,
          parallel_tool_calls: false
        )

        expect(params[:tool_choice]).to eq(choice)
      end
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
end
