require "langchain"

# gem install chroma-db
# or add `gem "chroma-db", "~> 0.3.0"` to your Gemfile

# Instantiate the Chroma client
chroma = Vectorsearch::Chroma.new(
  url: ENV["CHROMA_URL"],
  index_name: "documents",
  llm: :openai,
  llm_api_key: ENV["OPENAI_API_KEY"]
)

# Create the default schema.
chroma.create_default_schema

# Set up an array of PDF and TXT documents
docs = [
  Langchain.root.join("/docs/document.pdf"),
  Langchain.root.join("/docs/document.txt")
]

# Add data to the index. Weaviate will use OpenAI to generate embeddings behind the scene.
chroma.add_texts(
  texts: docs
)

# Query your data
chroma.similarity_search(
  query: "..."
)

# Interact with your index through Q&A
chroma.ask(
  question: "..."
)
