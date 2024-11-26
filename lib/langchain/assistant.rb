# frozen_string_literal: true

module Langchain
  # Assistants are Agent-like objects that leverage helpful instructions, LLMs, tools and knowledge to respond to user queries.
  # Assistants can be configured with an LLM of your choice, any vector search database and easily extended with additional tools.
  #
  # Usage:
  #     llm = Langchain::LLM::GoogleGemini.new(api_key: ENV["GOOGLE_GEMINI_API_KEY"])
  #     assistant = Langchain::Assistant.new(
  #       llm: llm,
  #       instructions: "You're a News Reporter AI",
  #       tools: [Langchain::Tool::NewsRetriever.new(api_key: ENV["NEWS_API_KEY"])]
  #     )
  class Assistant
    attr_reader :llm,
      :instructions,
      :state,
      :llm_adapter,
      :messages,
      :tool_choice,
      :total_prompt_tokens,
      :total_completion_tokens,
      :total_tokens

    attr_accessor :tools,
      :add_message_callback,
      :tool_execution_callback,
      :parallel_tool_calls

    # Create a new assistant
    #
    # @param llm [Langchain::LLM::Base] LLM instance that the assistant will use
    # @param tools [Array<Langchain::Tool::Base>] Tools that the assistant has access to
    # @param instructions [String] The system instructions
    # @param tool_choice [String] Specify how tools should be selected. Options: "auto", "any", "none", or <specific function name>
    # @param parallel_tool_calls [Boolean] Whether or not to run tools in parallel
    # @param messages [Array<Langchain::Assistant::Messages::Base>] The messages
    # @param add_message_callback [Proc] A callback function (Proc or lambda) that is called when any message is added to the conversation
    # @param tool_execution_callback [Proc] A callback function (Proc or lambda) that is called right before a tool function is executed
    def initialize(
      llm:,
      tools: [],
      instructions: nil,
      tool_choice: "auto",
      parallel_tool_calls: true,
      messages: [],
      # Callbacks
      add_message_callback: nil,
      tool_execution_callback: nil,
      &block
    )
      unless tools.is_a?(Array) && tools.all? { |tool| tool.class.singleton_class.included_modules.include?(Langchain::ToolDefinition) }
        raise ArgumentError, "Tools must be an array of objects extending Langchain::ToolDefinition"
      end

      @llm = llm
      @llm_adapter = LLM::Adapter.build(llm)

      @add_message_callback = add_message_callback if validate_callback!("add_message_callback", add_message_callback)
      @tool_execution_callback = tool_execution_callback if validate_callback!("tool_execution_callback", tool_execution_callback)

      self.messages = messages
      @tools = tools
      @parallel_tool_calls = parallel_tool_calls
      self.tool_choice = tool_choice
      self.instructions = instructions
      @block = block
      @state = :ready

      @total_prompt_tokens = 0
      @total_completion_tokens = 0
      @total_tokens = 0
    end

    # Add a user message to the messages array
    #
    # @param role [String] The role attribute of the message. Default: "user"
    # @param content [String] The content of the message
    # @param image_url [String] The URL of the image to include in the message
    # @param tool_calls [Array<Hash>] The tool calls to include in the message
    # @param tool_call_id [String] The ID of the tool call to include in the message
    # @return [Array<Langchain::Message>] The messages
    def add_message(role: "user", content: nil, image_url: nil, tool_calls: [], tool_call_id: nil)
      message = build_message(role: role, content: content, image_url: image_url, tool_calls: tool_calls, tool_call_id: tool_call_id)

      # Call the callback with the message
      add_message_callback.call(message) if add_message_callback # rubocop:disable Style/SafeNavigation

      # Prepend the message to the messages array
      messages << message

      @state = :ready

      messages
    end

    # Convert messages to an LLM APIs-compatible array of hashes
    #
    # @return [Array<Hash>] Messages as an OpenAI API-compatible array of hashes
    def array_of_message_hashes
      messages
        .map(&:to_hash)
        .compact
    end

    # Only used by the Assistant when it calls the LLM#complete() method
    def prompt_of_concatenated_messages
      messages.map(&:to_s).join
    end

    # Set multiple messages
    #
    # @param messages [Array<Langchain::Message>] The messages to set
    # @return [Array<Langchain::Message>] The messages
    def messages=(messages)
      raise ArgumentError, "messages array must only contain Langchain::Message instance(s)" unless messages.is_a?(Array) && messages.all? { |m| m.is_a?(Messages::Base) }

      @messages = messages
    end

    # Add multiple messages
    #
    # @param messages [Array<Hash>] The messages to add
    # @return [Array<Langchain::Message>] The messages
    def add_messages(messages:)
      messages.each do |message_hash|
        add_message(**message_hash.slice(:content, :role, :tool_calls, :tool_call_id))
      end
    end

    # Run the assistant
    #
    # @param auto_tool_execution [Boolean] Whether or not to automatically run tools
    # @return [Array<Langchain::Message>] The messages
    def run(auto_tool_execution: false)
      if messages.empty?
        Langchain.logger.warn("#{self.class} - No messages to process")
        @state = :completed
        return
      end

      @state = :in_progress
      @state = handle_state until run_finished?(auto_tool_execution)

      messages
    end

    # Run the assistant with automatic tool execution
    #
    # @return [Array<Langchain::Message>] The messages
    def run!
      run(auto_tool_execution: true)
    end

    # Add a user message and run the assistant
    #
    # @param content [String] The content of the message
    # @param auto_tool_execution [Boolean] Whether or not to automatically run tools
    # @return [Array<Langchain::Message>] The messages
    def add_message_and_run(content: nil, image_url: nil, auto_tool_execution: false)
      add_message(content: content, image_url: image_url, role: "user")
      run(auto_tool_execution: auto_tool_execution)
    end

    # Add a user message and run the assistant with automatic tool execution
    #
    # @param content [String] The content of the message
    # @return [Array<Langchain::Message>] The messages
    def add_message_and_run!(content: nil, image_url: nil)
      add_message_and_run(content: content, image_url: image_url, auto_tool_execution: true)
    end

    # Submit tool output
    #
    # @param tool_call_id [String] The ID of the tool call to submit output for
    # @param output [String] The output of the tool
    # @return [Array<Langchain::Message>] The messages
    def submit_tool_output(tool_call_id:, output:)
      # TODO: Validate that `tool_call_id` is valid by scanning messages and checking if this tool call ID was invoked
      add_message(role: @llm_adapter.tool_role, content: output, tool_call_id: tool_call_id)
    end

    # Delete all messages
    #
    # @return [Array] Empty messages array
    def clear_messages!
      # TODO: If this a bug? Should we keep the "system" message?
      @messages = []
    end

    # Set new instructions
    #
    # @param new_instructions [String] New instructions that will be set as a system message
    # @return [Array<Langchain::Message>] The messages
    def instructions=(new_instructions)
      @instructions = new_instructions

      if @llm_adapter.support_system_message?
        # TODO: Should we still set a system message even if @instructions is "" or nil?
        replace_system_message!(content: new_instructions)
      end
    end

    # Set tool_choice, how tools should be selected
    #
    # @param new_tool_choice [String] Tool choice
    # @return [String] Selected tool choice
    def tool_choice=(new_tool_choice)
      validate_tool_choice!(new_tool_choice)
      @tool_choice = new_tool_choice
    end

    private

    # Replace old system message with new one
    #
    # @param content [String] New system message content
    # @return [Array<Langchain::Message>] The messages
    def replace_system_message!(content:)
      messages.delete_if(&:system?)
      return if content.nil?

      message = build_message(role: "system", content: content)
      messages.unshift(message)
    end

    # TODO: If tool_choice = "tool_function_name" and then tool is removed from the assistant, should we set tool_choice back to "auto"?
    def validate_tool_choice!(tool_choice)
      allowed_tool_choices = llm_adapter.allowed_tool_choices.concat(available_tool_names)
      unless allowed_tool_choices.include?(tool_choice)
        raise ArgumentError, "Tool choice must be one of: #{allowed_tool_choices.join(", ")}"
      end
    end

    # Check if the run is finished
    #
    # @param auto_tool_execution [Boolean] Whether or not to automatically run tools
    # @return [Boolean] Whether the run is finished
    def run_finished?(auto_tool_execution)
      finished_states = [:completed, :failed]

      requires_manual_action = (@state == :requires_action) && !auto_tool_execution
      finished_states.include?(@state) || requires_manual_action
    end

    # Handle the current state and transition to the next state
    #
    # @return [Symbol] The next state
    def handle_state
      case @state
      when :in_progress
        process_latest_message
      when :requires_action
        execute_tools
      end
    end

    # Process the latest message
    #
    # @return [Symbol] The next state
    def process_latest_message
      last_message = messages.last

      case last_message.standard_role
      when :system
        handle_system_message
      when :llm
        handle_llm_message
      when :user, :tool
        handle_user_or_tool_message
      else
        handle_unexpected_message
      end
    end

    # Handle system message scenario
    #
    # @return [Symbol] The completed state
    def handle_system_message
      Langchain.logger.warn("#{self.class} - At least one user message is required after a system message")
      :completed
    end

    # Handle LLM message scenario
    #
    # @return [Symbol] The next state
    def handle_llm_message
      messages.last.tool_calls.any? ? :requires_action : :completed
    end

    # Handle unexpected message scenario
    #
    # @return [Symbol] The failed state
    def handle_unexpected_message
      Langchain.logger.error("#{self.class} - Unexpected message role encountered: #{messages.last.standard_role}")
      :failed
    end

    # Handle user or tool message scenario by processing the LLM response
    #
    # @return [Symbol] The next state
    def handle_user_or_tool_message
      response = chat_with_llm

      add_message(role: response.role, content: response.chat_completion, tool_calls: response.tool_calls)
      record_used_tokens(response.prompt_tokens, response.completion_tokens, response.total_tokens)

      set_state_for(response: response)
    end

    def set_state_for(response:)
      if response.tool_calls.any?
        :in_progress
      elsif response.chat_completion
        :completed
      elsif response.completion # Currently only used by Ollama
        :completed
      else
        Langchain.logger.error("#{self.class} - LLM response does not contain tool calls, chat or completion response")
        :failed
      end
    end

    # Execute the tools based on the tool calls in the last message
    #
    # @return [Symbol] The next state
    def execute_tools
      run_tools(messages.last.tool_calls)
      :in_progress
    rescue => e
      Langchain.logger.error("#{self.class} - Error running tools: #{e.message}; #{e.backtrace.join('\n')}")
      :failed
    end

    # Call to the LLM#chat() method
    #
    # @return [Langchain::LLM::BaseResponse] The LLM response object
    def chat_with_llm
      Langchain.logger.debug("#{self.class} - Sending a call to #{llm.class}")

      params = @llm_adapter.build_chat_params(
        instructions: @instructions,
        messages: array_of_message_hashes,
        tools: @tools,
        tool_choice: tool_choice,
        parallel_tool_calls: parallel_tool_calls
      )
      @llm.chat(**params, &@block)
    end

    # Run the tools automatically
    #
    # @param tool_calls [Array<Hash>] The tool calls to run
    def run_tools(tool_calls)
      # Iterate over each function invocation and submit tool output
      tool_calls.each do |tool_call|
        run_tool(tool_call)
      end
    end

    # Run the tool call
    #
    # @param tool_call [Hash] The tool call to run
    # @return [Object] The result of the tool call
    def run_tool(tool_call)
      tool_call_id, tool_name, method_name, tool_arguments = @llm_adapter.extract_tool_call_args(tool_call: tool_call)

      tool_instance = tools.find do |t|
        t.class.tool_name == tool_name
      end or raise ArgumentError, "Tool: #{tool_name} not found in assistant.tools"

      # Call the callback if set
      tool_execution_callback.call(tool_call_id, tool_name, method_name, tool_arguments) if tool_execution_callback # rubocop:disable Style/SafeNavigation
      output = tool_instance.send(method_name, **tool_arguments)

      submit_tool_output(tool_call_id: tool_call_id, output: output)
    end

    # Build a message
    #
    # @param role [String] The role of the message
    # @param content [String] The content of the message
    # @param image_url [String] The URL of the image to include in the message
    # @param tool_calls [Array<Hash>] The tool calls to include in the message
    # @param tool_call_id [String] The ID of the tool call to include in the message
    # @return [Langchain::Message] The Message object
    def build_message(role:, content: nil, image_url: nil, tool_calls: [], tool_call_id: nil)
      @llm_adapter.build_message(role: role, content: content, image_url: image_url, tool_calls: tool_calls, tool_call_id: tool_call_id)
    end

    # Increment the tokens count based on the last interaction with the LLM
    #
    # @param prompt_tokens [Integer] The number of used prmopt tokens
    # @param completion_tokens [Integer] The number of used completion tokens
    # @param total_tokens [Integer] The total number of used tokens
    # @return [Integer] The current total tokens count
    def record_used_tokens(prompt_tokens, completion_tokens, total_tokens_from_operation)
      @total_prompt_tokens += prompt_tokens if prompt_tokens
      @total_completion_tokens += completion_tokens if completion_tokens
      @total_tokens += total_tokens_from_operation if total_tokens_from_operation
    end

    def available_tool_names
      llm_adapter.available_tool_names(tools)
    end

    def validate_callback!(attr_name, callback)
      if !callback.nil? && !callback.respond_to?(:call)
        raise ArgumentError, "#{attr_name} must be a callable object, like Proc or lambda"
      end

      true
    end
  end
end
