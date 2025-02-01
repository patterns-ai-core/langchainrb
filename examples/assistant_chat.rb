require "dotenv/load"
require "langchain"
require "openai"
require "reline"

# gem install reline
# or add `gem "reline"` to your Gemfile

DONE = %w[done end eof print exit].freeze

def prompt_for_message
  puts "\n(multiline input; type 'end' on its own line when done. or 'print' to print messages, or 'exit' to exit)\n\n"

  user_message = Reline.readmultiline("Query: ", true) do |multiline_input|
    last = multiline_input.split.last
    DONE.include?(last)
  end

  return :noop unless user_message
  return :print if user_message == "print"

  lines = user_message.split("\n")

  if lines.size > 1 && DONE.include?(lines.last)
    # remove the "done" from the message
    user_message = lines[0..-2].join("\n")
  end

  return :exit if DONE.include?(user_message.downcase)

  user_message
end

def print_messages(assistant)
  puts "\n"
  assistant.messages.each do |message|
    puts "----"
    puts message.role + " role content: " + message.content
    case message.role
    when "assistant"
      message.tool_calls.each do |tool_call|
        puts " " + tool_call["function"]["name"] + ": " << tool_call["function"]["arguments"]
      end
    when "tool"
      puts " tool_call_id: " + message.tool_call_id
    end
  end
  puts "-------"
end

begin
  llm = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])

  # Or use local Ollama. See https://ollama.com/search?c=tools for models that support tools.
  # llm = Langchain::LLM::Ollama.new(default_options: {chat_model: "mistral"})

  assistant = Langchain::Assistant.new(
    llm: llm,
    instructions: "You are a Meteorologist Assistant that is able to report the weather for any city in metric units.",
    tools: [
      Langchain::Tool::Weather.new(api_key: ENV["OPEN_WEATHER_API_KEY"])
    ]
  )

  puts "Welcome to your Meteorological assistant!"

  loop do
    user_message = prompt_for_message

    case user_message
    when :noop
      next
    when :print
      print_messages(assistant)
      next
    when :exit
      break
    end

    assistant.add_message_and_run content: user_message, auto_tool_execution: true
    puts assistant.messages.last.content + "\n"
  end
rescue Interrupt
  exit 0
end
