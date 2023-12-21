# frozen_string_literal: true

module Langchain
  class Assistant
    attr_reader :name, :llm, :thread, :instructions, :description

    attr_accessor :tools

    # @param name [String] The name of the assistant
    # @param llm [Langchain::LLM::Base] The LLM instance to use for the assistant
    # @param thread [Langchain::Thread] The thread to use for the assistant
    # @param tools [Array<Langchain::Tool::Base>] The tools to use for the assistant
    # @param instructions [String] The instructions to use for the assistant
    # @param description [String] The description of the assistant
    def initialize(
      name:,
      llm:,
      thread:,
      tools: [],
      instructions: nil,
      description: nil
    )
      # Check that the LLM class implements the `chat()` instance method
      raise ArgumentError, "LLM must implement `chat()` method" unless llm.class.instance_methods(false).include?(:chat)
      raise ArgumentError, "Thread must be an instance of Langchain::Thread" unless thread.is_a?(Langchain::Thread)
      raise ArgumentError, "Tools must be an array of Langchain::Tool::Base instance(s)" unless tools.is_a?(Array) && tools.all? { |tool| tool.is_a?(Langchain::Tool::Base) }

      @name = name
      @llm = llm
      @thread = thread
      @instructions = instructions
      @tools = tools
      @description = description
    end

    # Add a user message to the thread
    #
    # @param text [String] The text of the message
    def add_message(text:, role: "user")
      message = build_message(role: role, text: text)
      add_message_to_thread(message)
    end

    # Run the assistant
    #
    # @param auto_tool_execution [Boolean] Whether or not to automatically run tools
    # @return [Array<Langchain::Message>] The messages in the thread
    def run(auto_tool_execution: false)
      prompt = build_assistant_prompt(instructions: instructions, tools: tools)
      response = llm.chat(prompt: prompt)

      add_message(text: response.chat_completion, role: response.role)

      if auto_tool_execution
        run_tools(response.chat_completion)
      end

      thread.messages
    end

    # Add a user message to the thread and run the assistant
    #
    # @param text [String] The text of the message
    # @param auto_tool_execution [Boolean] Whether or not to automatically run tools
    # @return [Array<Langchain::Message>] The messages in the thread
    def add_message_and_run(text:, auto_tool_execution: false)
      add_message(text: text)
      run(auto_tool_execution: auto_tool_execution)
    end

    # Submit tool output to the thread
    #
    # @param tool_name [String] The name of the tool that generated the output
    # @param output [String] The output of the tool
    # @return [Array<Langchain::Message>] The messages in the thread
    def submit_tool_output(tool_name:, output:)
      raise ArgumentError, "Invalid tool_name; not found in assistant.tools" unless tools.find { |t| t.name == tool_name }

      message = build_message(role: "#{tool_name}_output", text: output)
      add_message_to_thread(message)
    end

    private

    # Run all the tools when auto_tool_execution: true
    #
    # @param completion [String] The completion from the LLM
    def run_tools(completion)
      # Iterate over each tool and tool_input and submit tool output
      # We may need to run this in a while() loop to handle subsequent tool invocations
      find_tool_invocations(completion).each_with_index do |tool_invocation, _index|
        tool_instance = tools.find { |t| t.name == tool_invocation[:tool_name] }
        output = tool_instance.execute(input: tool_invocation[:tool_input])

        submit_tool_output(tool_name: tool_invocation[:tool_name], output: output)

        prompt = build_assistant_prompt(instructions: instructions, tools: tools)
        response = llm.chat(prompt: prompt)

        add_message(text: response.chat_completion, role: response.role)
      end
    end

    # Does it make sense to introduce a state machine so that :requires_action is one of the states for example?
    def find_tool_invocations(completion)
      invoked_tools = []

      # Find all instances of tool invocations
      tools.each do |tool|
        completion.scan(/<#{tool.name}>(.*)<\/#{tool.name}>/m) # /./m - Any character (the m modifier enables multiline mode)
          .flatten
          .each do |tool_input|
            invoked_tools.push({tool_name: tool.name, tool_input: tool_input})
          end
      end

      invoked_tools
    end

    # Build the chat history
    #
    # @return [String] The chat history
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
      prompts = []

      prompts.push(instructions_prompt(instructions: instructions)) if !instructions.empty?
      prompts.push(tools_prompt(tools: tools)) if tools.any?
      prompts.push(chat_history_prompt(chat_history: chat_history))

      prompts.join("\n\n")
    end

    # Chat history prompt
    #
    # @param chat_history [String] The chat history to use
    # @return [String] The chat history prompt
    def chat_history_prompt(chat_history:)
      Langchain::Prompt
        .load_from_path(file_path: "lib/langchain/assistants/prompts/chat_history_prompt.yaml")
        .format(chat_history: chat_history)
    end

    # Instructions prompt
    #
    # @param instructions [String] The instructions to use
    # @return [String] The instructions prompt
    def instructions_prompt(instructions:)
      Langchain::Prompt
        .load_from_path(file_path: "lib/langchain/assistants/prompts/instructions_prompt.yaml")
        .format(instructions: instructions)
    end

    # Tools prompt
    #
    # @param tools [Array<Langchain::Tool::Base>] The tools to use
    # @return [String] The tools prompt
    def tools_prompt(tools:)
      Langchain::Prompt
        .load_from_path(file_path: "lib/langchain/assistants/prompts/tools_prompt.yaml")
        .format(
          tools: tools
            .map(&:name_and_description)
            .join("\n")
        )
    end

    def build_assistant_prompt(instructions:, tools:)
      prompt = assistant_prompt(instructions: instructions, tools: tools, chat_history: build_chat_history)

      while begin
        # Return false to exit the while loop
        !llm.class.const_get(:LENGTH_VALIDATOR).validate_max_tokens!(
          prompt,
          llm.defaults[:chat_completion_model_name],
          {llm: llm}
        )
      # Rescue error if context window is exceeded and return true to continue the while loop
      rescue Langchain::Utils::TokenLength::TokenLimitExceeded
        true
      end
        # Check if the prompt exceeds the context window

        # Truncate the oldest messages when the context window is exceeded
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
