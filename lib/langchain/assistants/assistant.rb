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
    extend Forwardable
    def_delegators :thread, :messages

    attr_reader :llm, :thread, :instructions, :state, :llm_adapter, :tool_choice
    attr_reader :total_prompt_tokens, :total_completion_tokens, :total_tokens
    attr_accessor :tools

    # Create a new assistant
    #
    # @param llm [Langchain::LLM::Base] LLM instance that the assistant will use
    # @param thread [Langchain::Thread] The thread that'll keep track of the conversation
    # @param tools [Array<Langchain::Tool::Base>] Tools that the assistant has access to
    # @param instructions [String] The system instructions to include in the thread
    def initialize(
      llm:,
      thread: nil,
      tools: [],
      instructions: nil,
      tool_choice: "auto"
    )
      unless tools.is_a?(Array) && tools.all? { |tool| tool.class.singleton_class.included_modules.include?(Langchain::ToolDefinition) }
        raise ArgumentError, "Tools must be an array of objects extending Langchain::ToolDefinition"
      end

      @llm = llm
      @llm_adapter = LLM::Adapter.build(llm)
      @thread = thread || Langchain::Thread.new
      @tools = tools
      self.tool_choice = tool_choice
      @instructions = instructions
      @state = :ready

      @total_prompt_tokens = 0
      @total_completion_tokens = 0
      @total_tokens = 0

      raise ArgumentError, "Thread must be an instance of Langchain::Thread" unless @thread.is_a?(Langchain::Thread)

      # The first message in the thread should be the system instructions
      # TODO: What if the user added old messages and the system instructions are already in there? Should this overwrite the existing instructions?
      initialize_instructions
      # For Google Gemini, and Anthropic system instructions are added to the `system:` param in the `chat` method
    end

    # Add a user message to the thread
    #
    # @param content [String] The content of the message
    # @param role [String] The role attribute of the message. Default: "user"
    # @param tool_calls [Array<Hash>] The tool calls to include in the message
    # @param tool_call_id [String] The ID of the tool call to include in the message
    # @return [Array<Langchain::Message>] The messages in the thread
    def add_message(content: nil, role: "user", tool_calls: [], tool_call_id: nil)
      message = build_message(role: role, content: content, tool_calls: tool_calls, tool_call_id: tool_call_id)
      messages = thread.add_message(message)
      @state = :ready

      messages
    end

    # Set multiple messages to the thread
    #
    # @param messages [Array<Hash>] The messages to set
    # @return [Array<Langchain::Message>] The messages in the thread
    def messages=(messages)
      clear_thread!
      add_messages(messages: messages)
    end

    # Add multiple messages to the thread
    #
    # @param messages [Array<Hash>] The messages to add
    # @return [Array<Langchain::Message>] The messages in the thread
    def add_messages(messages:)
      messages.each do |message_hash|
        add_message(**message_hash.slice(:content, :role, :tool_calls, :tool_call_id))
      end
    end

    # Run the assistant
    #
    # @param auto_tool_execution [Boolean] Whether or not to automatically run tools
    # @return [Array<Langchain::Message>] The messages in the thread
    def run(auto_tool_execution: false)
      if thread.messages.empty?
        Langchain.logger.warn("No messages in the thread")
        @state = :completed
        return
      end

      @state = :in_progress
      @state = handle_state until run_finished?(auto_tool_execution)

      thread.messages
    end

    # Add a user message to the thread and run the assistant
    #
    # @param content [String] The content of the message
    # @param auto_tool_execution [Boolean] Whether or not to automatically run tools
    # @return [Array<Langchain::Message>] The messages in the thread
    def add_message_and_run(content:, auto_tool_execution: false)
      add_message(content: content, role: "user")
      run(auto_tool_execution: auto_tool_execution)
    end

    # Submit tool output to the thread
    #
    # @param tool_call_id [String] The ID of the tool call to submit output for
    # @param output [String] The output of the tool
    # @return [Array<Langchain::Message>] The messages in the thread
    def submit_tool_output(tool_call_id:, output:)
      tool_role = determine_tool_role

      # TODO: Validate that `tool_call_id` is valid by scanning messages and checking if this tool call ID was invoked
      add_message(role: tool_role, content: output, tool_call_id: tool_call_id)
    end

    # Delete all messages in the thread
    #
    # @return [Array] Empty messages array
    def clear_thread!
      # TODO: If this a bug? Should we keep the "system" message?
      thread.messages = []
    end

    # Set new instructions
    #
    # @param [String] New instructions that will be set as a system message
    # @return [Array<Langchain::Message>] The messages in the thread
    def instructions=(new_instructions)
      @instructions = new_instructions

      # Find message with role: "system" in thread.messages and delete it from the thread.messages array
      thread.messages.delete_if(&:system?)

      # Set new instructions by adding new system message
      message = build_message(role: "system", content: new_instructions)
      thread.messages.unshift(message)
    end

    def tool_choice=(new_tool_choice)
      validate_tool_choice!(new_tool_choice)
      @tool_choice = new_tool_choice
    end

    private

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

    # Process the latest message in the thread
    #
    # @return [Symbol] The next state
    def process_latest_message
      last_message = thread.messages.last

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
      Langchain.logger.warn("At least one user message is required after a system message")
      :completed
    end

    # Handle LLM message scenario
    #
    # @return [Symbol] The next state
    def handle_llm_message
      thread.messages.last.tool_calls.any? ? :requires_action : :completed
    end

    # Handle unexpected message scenario
    #
    # @return [Symbol] The failed state
    def handle_unexpected_message
      Langchain.logger.error("Unexpected message role encountered: #{thread.messages.last.standard_role}")
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
        Langchain.logger.error("LLM response does not contain tool calls, chat or completion response")
        :failed
      end
    end

    # Execute the tools based on the tool calls in the last message
    #
    # @return [Symbol] The next state
    def execute_tools
      run_tools(thread.messages.last.tool_calls)
      :in_progress
    rescue => e
      Langchain.logger.error("Error running tools: #{e.message}; #{e.backtrace.join('\n')}")
      :failed
    end

    # Determine the tool role based on the LLM type
    #
    # @return [String] The tool role
    def determine_tool_role
      case llm
      when Langchain::LLM::Anthropic
        Langchain::Messages::AnthropicMessage::TOOL_ROLE
      when Langchain::LLM::GoogleGemini, Langchain::LLM::GoogleVertexAI
        Langchain::Messages::GoogleGeminiMessage::TOOL_ROLE
      when Langchain::LLM::MistralAI
        Langchain::Messages::MistralAIMessage::TOOL_ROLE
      when Langchain::LLM::Ollama
        Langchain::Messages::OllamaMessage::TOOL_ROLE
      when Langchain::LLM::OpenAI
        Langchain::Messages::OpenAIMessage::TOOL_ROLE
      end
    end

    def initialize_instructions
      if llm.is_a?(Langchain::LLM::OpenAI)
        add_message(role: "system", content: instructions) if instructions
      end
    end

    # Call to the LLM#chat() method
    #
    # @return [Langchain::LLM::BaseResponse] The LLM response object
    def chat_with_llm
      Langchain.logger.info("Sending a call to #{llm.class}", for: self.class)

      params = @llm_adapter.build_chat_params(
        instructions: @instructions,
        messages: thread.array_of_message_hashes,
        tools: @tools,
        tool_choice: tool_choice
      )
      @llm.chat(**params)
    end

    # Run the tools automatically
    #
    # @param tool_calls [Array<Hash>] The tool calls to run
    def run_tools(tool_calls)
      # Iterate over each function invocation and submit tool output
      tool_calls.each do |tool_call|
        tool_call_id, tool_name, method_name, tool_arguments = @llm_adapter.extract_tool_call_args(tool_call: tool_call)

        tool_instance = tools.find do |t|
          t.class.tool_name == tool_name
        end or raise ArgumentError, "Tool: #{tool_name} not found in assistant.tools"

        output = tool_instance.send(method_name, **tool_arguments)

        submit_tool_output(tool_call_id: tool_call_id, output: output)
      end
    end

    # Build a message
    #
    # @param role [String] The role of the message
    # @param content [String] The content of the message
    # @param tool_calls [Array<Hash>] The tool calls to include in the message
    # @param tool_call_id [String] The ID of the tool call to include in the message
    # @return [Langchain::Message] The Message object
    def build_message(role:, content: nil, tool_calls: [], tool_call_id: nil)
      @llm_adapter.build_message(role: role, content: content, tool_calls: tool_calls, tool_call_id: tool_call_id)
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

    # TODO: Fix the message truncation when context window is exceeded

    module LLM
      class Adapter
        def self.build(llm)
          case llm
          when Langchain::LLM::Anthropic
            Adapters::Anthropic.new
          when Langchain::LLM::GoogleGemini, Langchain::LLM::GoogleVertexAI
            Adapters::GoogleGemini.new
          when Langchain::LLM::MistralAI
            Adapters::MistralAI.new
          when Langchain::LLM::Ollama
            Adapters::Ollama.new
          when Langchain::LLM::OpenAI
            Adapters::OpenAI.new
          else
            raise ArgumentError, "Unsupported LLM type: #{llm.class}"
          end
        end
      end

      module Adapters
        class Base
          def build_chat_params(tools:, instructions:, messages:, tool_choice:)
            raise NotImplementedError, "Subclasses must implement build_chat_params"
          end

          def extract_tool_call_args(tool_call:)
            raise NotImplementedError, "Subclasses must implement extract_tool_call_args"
          end

          def build_message(role:, content: nil, tool_calls: [], tool_call_id: nil)
            raise NotImplementedError, "Subclasses must implement build_message"
          end
        end

        class Ollama < Base
          def build_chat_params(tools:, instructions:, messages:, tool_choice:)
            params = {messages: messages}
            if tools.any?
              params[:tools] = build_tools(tools)
            end
            params
          end

          def build_message(role:, content: nil, tool_calls: [], tool_call_id: nil)
            Langchain::Messages::OllamaMessage.new(role: role, content: content, tool_calls: tool_calls, tool_call_id: tool_call_id)
          end

          # Extract the tool call information from the OpenAI tool call hash
          #
          # @param tool_call [Hash] The tool call hash
          # @return [Array] The tool call information
          def extract_tool_call_args(tool_call:)
            tool_call_id = tool_call.dig("id")

            function_name = tool_call.dig("function", "name")
            tool_name, method_name = function_name.split("__")

            tool_arguments = tool_call.dig("function", "arguments")
            tool_arguments = if tool_arguments.is_a?(Hash)
              Langchain::Utils::HashTransformer.symbolize_keys(tool_arguments)
            else
              JSON.parse(tool_arguments, symbolize_names: true)
            end

            [tool_call_id, tool_name, method_name, tool_arguments]
          end

          def available_tool_names(tools)
            build_tools(tools).map { |tool| tool.dig(:function, :name) }
          end

          def allowed_tool_choices
            ["auto", "none"]
          end

          private

          def build_tools(tools)
            tools.map { |tool| tool.class.function_schemas.to_openai_format }.flatten
          end
        end

        class OpenAI < Base
          def build_chat_params(tools:, instructions:, messages:, tool_choice:)
            params = {messages: messages}
            if tools.any?
              params[:tools] = build_tools(tools)
              params[:tool_choice] = build_tool_choice(tool_choice)
            end
            params
          end

          def build_message(role:, content: nil, tool_calls: [], tool_call_id: nil)
            Langchain::Messages::OpenAIMessage.new(role: role, content: content, tool_calls: tool_calls, tool_call_id: tool_call_id)
          end

          # Extract the tool call information from the OpenAI tool call hash
          #
          # @param tool_call [Hash] The tool call hash
          # @return [Array] The tool call information
          def extract_tool_call_args(tool_call:)
            tool_call_id = tool_call.dig("id")

            function_name = tool_call.dig("function", "name")
            tool_name, method_name = function_name.split("__")

            tool_arguments = tool_call.dig("function", "arguments")
            tool_arguments = if tool_arguments.is_a?(Hash)
              Langchain::Utils::HashTransformer.symbolize_keys(tool_arguments)
            else
              JSON.parse(tool_arguments, symbolize_names: true)
            end

            [tool_call_id, tool_name, method_name, tool_arguments]
          end

          def build_tools(tools)
            tools.map { |tool| tool.class.function_schemas.to_openai_format }.flatten
          end

          def allowed_tool_choices
            ["auto", "none"]
          end

          def available_tool_names(tools)
            build_tools(tools).map { |tool| tool.dig(:function, :name) }
          end

          private

          def build_tool_choice(choice)
            case choice
            when "auto"
              choice
            else
              {"type" => "function", "function" => {"name" => choice}}
            end
          end
        end

        class MistralAI < Base
          def build_chat_params(tools:, instructions:, messages:, tool_choice:)
            params = {messages: messages}
            if tools.any?
              params[:tools] = build_tools(tools)
              params[:tool_choice] = build_tool_choice(tool_choice)
            end
            params
          end

          def build_message(role:, content: nil, tool_calls: [], tool_call_id: nil)
            Langchain::Messages::OpenAIMessage.new(role: role, content: content, tool_calls: tool_calls, tool_call_id: tool_call_id)
          end

          # Extract the tool call information from the OpenAI tool call hash
          #
          # @param tool_call [Hash] The tool call hash
          # @return [Array] The tool call information
          def extract_tool_call_args(tool_call:)
            tool_call_id = tool_call.dig("id")

            function_name = tool_call.dig("function", "name")
            tool_name, method_name = function_name.split("__")

            tool_arguments = tool_call.dig("function", "arguments")
            tool_arguments = if tool_arguments.is_a?(Hash)
              Langchain::Utils::HashTransformer.symbolize_keys(tool_arguments)
            else
              JSON.parse(tool_arguments, symbolize_names: true)
            end

            [tool_call_id, tool_name, method_name, tool_arguments]
          end

          def build_tools(tools)
            tools.map { |tool| tool.class.function_schemas.to_openai_format }.flatten
          end

          def allowed_tool_choices
            ["auto", "none"]
          end

          def available_tool_names(tools)
            build_tools(tools).map { |tool| tool.dig(:function, :name) }
          end

          private

          def build_tool_choice(choice)
            case choice
            when "auto"
              choice
            else
              {"type" => "function", "function" => {"name" => choice}}
            end
          end
        end

        class GoogleGemini < Base
          def build_chat_params(tools:, instructions:, messages:, tool_choice:)
            params = {messages: messages}
            if tools.any?
              params[:tools] = build_tools(tools)
              params[:system] = instructions if instructions
              params[:tool_choice] = build_tool_config(tool_choice)
            end
            params
          end

          def build_message(role:, content: nil, tool_calls: [], tool_call_id: nil)
            Langchain::Messages::GoogleGeminiMessage.new(role: role, content: content, tool_calls: tool_calls, tool_call_id: tool_call_id)
          end

          # Extract the tool call information from the Google Gemini tool call hash
          #
          # @param tool_call [Hash] The tool call hash, format: {"functionCall"=>{"name"=>"weather__execute", "args"=>{"input"=>"NYC"}}}
          # @return [Array] The tool call information
          def extract_tool_call_args(tool_call:)
            tool_call_id = tool_call.dig("functionCall", "name")
            function_name = tool_call.dig("functionCall", "name")
            tool_name, method_name = function_name.split("__")
            tool_arguments = tool_call.dig("functionCall", "args").transform_keys(&:to_sym)
            [tool_call_id, tool_name, method_name, tool_arguments]
          end

          def build_tools(tools)
            tools.map { |tool| tool.class.function_schemas.to_google_gemini_format }.flatten
          end

          def allowed_tool_choices
            ["auto", "none"]
          end

          def available_tool_names(tools)
            build_tools(tools).map { |tool| tool.dig(:name) }
          end

          private

          def build_tool_config(choice)
            case choice
            when "auto"
              {function_calling_config: {mode: "auto"}}
            when "none"
              {function_calling_config: {mode: "none"}}
            else
              {function_calling_config: {mode: "any", allowed_function_names: [choice]}}
            end
          end
        end

        class Anthropic < Base
          def build_chat_params(tools:, instructions:, messages:, tool_choice:)
            params = {messages: messages}
            if tools.any?
              params[:tools] = build_tools(tools)
              params[:tool_choice] = build_tool_choice(tool_choice)
            end
            params[:system] = instructions if instructions
            params
          end

          def build_message(role:, content: nil, tool_calls: [], tool_call_id: nil)
            Langchain::Messages::AnthropicMessage.new(role: role, content: content, tool_calls: tool_calls, tool_call_id: tool_call_id)
          end

          # Extract the tool call information from the Anthropic tool call hash
          #
          # @param tool_call [Hash] The tool call hash, format: {"type"=>"tool_use", "id"=>"toolu_01TjusbFApEbwKPRWTRwzadR", "name"=>"news_retriever__get_top_headlines", "input"=>{"country"=>"us", "page_size"=>10}}], "stop_reason"=>"tool_use"}
          # @return [Array] The tool call information
          def extract_tool_call_args(tool_call:)
            tool_call_id = tool_call.dig("id")
            function_name = tool_call.dig("name")
            tool_name, method_name = function_name.split("__")
            tool_arguments = tool_call.dig("input").transform_keys(&:to_sym)
            [tool_call_id, tool_name, method_name, tool_arguments]
          end

          def build_tools(tools)
            tools.map { |tool| tool.class.function_schemas.to_anthropic_format }.flatten
          end

          def allowed_tool_choices
            ["auto", "any"]
          end

          def available_tool_names(tools)
            build_tools(tools).map { |tool| tool.dig(:name) }
          end

          private

          def build_tool_choice(choice)
            case choice
            when "auto"
              {type: "auto"}
            when "any"
              {type: "any"}
            else
              {type: "tool", name: choice}
            end
          end
        end
      end
    end
  end
end
