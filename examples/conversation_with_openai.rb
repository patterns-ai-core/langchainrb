require "langchain"
require "reline"
require "dotenv/load"

# gem install reline
# or add `gem "reline"` to your Gemfile

openai = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])

chat = Langchain::Conversation.new(llm: openai)
chat.set_context("You are a chatbot from the future")

DONE = %w[done end eof exit].freeze

puts "Welcome to the chatbot from the future!"

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

    puts chat.message(user_message)
  end
rescue Interrupt
  exit 0
end
