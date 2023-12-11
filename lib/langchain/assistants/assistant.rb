# frozen_string_literal: true

module Langchain
  class Assistant
    attr_reader :name, :llm, :thread, :instructions, :description

    attr_accessor :tools

    def initialize(
      name:,
      llm:,
      thread:,
      instructions:,
      tools: [],
      description: nil
    )
      @name = name
      @llm = llm
      @thread = thread
      @instructions = instructions
      @tools = tools
      @description = description
    end

    def add_message(text:, role: "user")
      # Add the message to the thread
      message = build_message(role: role, text: text)
      add_message_to_thread(message)
    end

    def run(auto_tool_execution: false)
      prompt = build_assistant_prompt(instructions: instructions, tools: tools)
      response = llm.chat(prompt: prompt)

      add_message(text: response.completion, role: response.role)

      if auto_tool_execution
        run_tools(response.completion)
      end

      thread.messages
    end

    # TODO: Need option to run tools automatically or not.
    def add_message_and_run(text:, auto_tool_execution: false)
      add_message(text: text)
      run(auto_tool_execution: auto_tool_execution)
    end

    def run_tools(completion)
      if (invoked_tools, tool_inputs = requires_action?(completion))
        # Iterate over each tool and tool_input and submit tool output
        invoked_tools.each_with_index do |tool, index|
          tool_instance = tools.find { |t| t.name == tool }
          output = tool_instance.execute(input: tool_inputs[index])

          submit_tool_output(output: output)

          prompt = build_assistant_prompt(instructions: instructions, tools: tools)
          response = llm.chat(prompt: prompt)

          add_message(text: response.completion, role: response.role)
        end
      end
    end

    def submit_tool_output(output:)
      # "<observation>#{observation}</observation>"
      # Question: Should the role actually be named "tool_name", like "google_search_tool" or "calculator_tool", etc.?
      # This could help tell the LLM where the observation came from.
      message = build_message(role: "tool_output", text: output)
      add_message_to_thread(message)
    end

    private

    # Does it make sense to introduce a state machine so that :requires_action is one of the states for example?
    def requires_action?(completion)
      # TODO: Need better mechanism to find all tool calls that did not have tool output submitted
      # ...because there could be multiple tool calls.

      # Find all instances of tool invocations
      invoked_tools = completion.scan(/<tool>(.*)<\/tool>/).flatten
      tool_inputs = completion.scan(/<tool_input>(.*)<\/tool_input>/).flatten

      [invoked_tools, tool_inputs]
    end

    # TODO: Summarize or truncate the conversation when it exceeds the context window
    # Truncate the oldest messages when the context window is exceeded
    def build_chat_history
      thread
        .messages
        .map(&:to_s)
        .join("\n")
    end

    def build_message(role:, text:)
      Message.new(role: role, text: text)
    end

    def assistant_prompt(instructions:, tools:, chat_history:)
      prompt = Langchain::Prompt.load_from_path(file_path: "lib/langchain/assistants/prompts/assistant_prompt.yaml")
      prompt.format(
        instructions: instructions,
        tools: tools
          .map(&:name_and_description)
          .join("\n"),
        chat_history: chat_history
      )
    end

    def build_assistant_prompt(instructions:, tools:)
      prompt = assistant_prompt(instructions: instructions, tools: tools, chat_history: build_chat_history)

      while (
        # Check if the prompt exceeds the context window
        begin
          # Return false to exit the while loop
          !llm.class.const_get("LENGTH_VALIDATOR").validate_max_tokens!(
            prompt, llm.defaults[:chat_completion_model_name]
          )
        # Rescue error if context window is exceeded and return true to continue the while loop
        rescue Langchain::Utils::TokenLength::TokenLimitExceeded
          true
        end
      )
        # Remove the oldest message from the thread
        thread.messages.shift
        prompt = assistant_prompt(instructions: instructions, tools: tools, chat_history: build_chat_history)
      end

      prompt
    end

    def add_message_to_thread(message)
      thread.messages << message
    end
  end
end
