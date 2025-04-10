# frozen_string_literal: true

require "langchain"
require "dotenv/load"
require "ruby/openai"

# Initialize the Pgvector client
pgvector = Langchain::Vectorsearch::Pgvector.new(
  url: ENV["POSTGRES_URL"],
  index_name: "documents",
  llm: Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
)

# Create the default schema if it doesn't exist
pgvector.create_default_schema

# Add documents with metadata
documents = [
  {
    text: "The quick brown fox jumps over the lazy dog",
    metadata: {
      source: "fables",
      author: "Aesop",
      category: "animals"
    }
  },
  {
    text: "To be or not to be, that is the question",
    metadata: {
      source: "hamlet",
      author: "Shakespeare",
      category: "drama"
    }
  },
  {
    text: "It was the best of times, it was the worst of times",
    metadata: {
      source: "tale_of_two_cities",
      author: "Dickens",
      category: "novel"
    }
  }
]

# Add texts with metadata
ids = pgvector.add_texts(
  texts: documents.map { |doc| doc[:text] },
  metadata: documents.map { |doc| doc[:metadata] }
)

puts "Added documents with IDs: #{ids.inspect}"

# Perform a similarity search
puts "\nSearching for documents similar to 'fox':"
results = pgvector.similarity_search(query: "fox", k: 2)
results.each do |result|
  puts "Content: #{result.content}"
  puts "Metadata: #{JSON.parse(result.metadata)}"
  puts "---"
end

# Search with specific metadata filter
puts "\nSearching for Shakespeare's works:"
results = pgvector.similarity_search(query: "drama", k: 1)
results.each do |result|
  metadata = JSON.parse(result.metadata)
  if metadata["author"] == "Shakespeare"
    puts "Found Shakespeare's work:"
    puts "Content: #{result.content}"
    puts "Metadata: #{metadata}"
  end
end

# Clean up (optional)
# pgvector.destroy_default_schema
