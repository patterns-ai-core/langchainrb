require_relative "../lib/langchain"
require "faraday"

llm = Langchain::LLM::Ollama.new(default_options: { chat_model: "llama3.2"})

assistant = Langchain::Assistant.new(llm: llm)

response = assistant.add_message_and_run(
  image_url: "https://gist.githubusercontent.com/andreibondarev/b6f444194d0ee7ab7302a4d83184e53e/raw/099e10af2d84638211e25866f71afa7308226365/sf-cable-car.jpg",
  content: "Please describe this image"
)

puts response.inspect
