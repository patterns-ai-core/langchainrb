require "langchain"

# Initialize the LLM (using Ollama in this example)
llm = Langchain::LLM::Ollama.new

# Initialize the SQLite-vec vectorstore
db = Langchain::Vectorsearch::SqliteVec.new(
  url: ":memory:", # Use a file-based DB by passing a path or ":memory:" for in-memory
  index_name: "documents",
  namespace: "test",
  llm: llm
)

# Create the schema
db.create_default_schema

# Add some sample texts
texts = [
  "Ruby is a dynamic, open source programming language with a focus on simplicity and productivity.",
  "Python is a programming language that lets you work quickly and integrate systems more effectively.",
  "JavaScript is a lightweight, interpreted programming language with first-class functions.",
  "Rust is a multi-paradigm, general-purpose programming language designed for performance and safety."
]

puts "Adding texts..."
ids = db.add_texts(texts: texts)
puts "Added #{ids.size} texts with IDs: #{ids.join(", ")}"

# Search for similar texts
query = "What programming language is focused on memory safety?"
puts "\nSearching for: #{query}"
results = db.similarity_search(query: query)

puts "\nResults:"
results.each do |result|
  puts "- #{result[1]}"
end

# Ask a question
question = "Which programming language emphasizes simplicity?"
puts "\nAsking: #{question}"
response = db.ask(question: question)
puts "Answer: #{response.chat_completion}"

# Clean up
db.destroy_default_schema