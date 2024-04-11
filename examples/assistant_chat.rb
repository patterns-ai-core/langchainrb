require "langchain"
require "openai"
require "reline"

# gem install reline
# or add `gem "reline"` to your Gemfile

openai = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
thread = Langchain::Thread.new
assistant = Langchain::Assistant.new(
  llm: openai,
  thread: thread,
  instructions: "You are a Meteorologist Assistant that is able to pull the weather for any location",
  tools: [
    Langchain::Tool::Weather.new(api_key: ENV["OPEN_WEATHER_API_KEY"])
  ]
)

DONE = %w[done end eof exit].freeze

puts "Welcome to your Meteorological assistant!"

def prompt_for_message
  puts "(multiline input; type 'end' on its own line when done. or exit to exit)"

  user_message = Reline.readmultiline("Question: ", true) do |multiline_input|
    last = multiline_input.split.last
    DONE.include?(last)
  end

  return :noop unless user_message

  lines = user_message.split("\n")
  if lines.size > 1 && DONE.include?(lines.last)
    # remove the "done" from the message
    user_message = lines[0..-2].join("\n")
  end

  return :exit if DONE.include?(user_message.downcase)

  user_message
end

begin
  loop do
    user_message = prompt_for_message

    case user_message
    when :noop
      next
    when :exit
      break
    end

    assistant.add_message_and_run content: user_message, auto_tool_execution: true
    puts assistant.thread.messages.last.content
  end
rescue Interrupt
  exit 0
end
