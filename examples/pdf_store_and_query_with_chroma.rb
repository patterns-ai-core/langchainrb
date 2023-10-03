require "langchain"
require "dotenv/load"

# gem install chroma-db
# or add `gem "chroma-db", "~> 0.6.0"` to your Gemfile

# Instantiate the Chroma client
chroma = Langchain::Vectorsearch::Chroma.new(
  url: ENV["CHROMA_URL"],
  index_name: "documents",
  llm: Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
)

# Create the default schema.
chroma.create_default_schema

# gem install these or add them to your Gemfile
# Add `gem "pdf-reader", "~> 1.4"` to your Gemfile
# Add `gem "docx", branch: "master", git: "https://github.com/ruby-docx/docx.git"` to your Gemfile

# Set up an array of PDF and TXT documents
docs = [
  Langchain.root.join("/docs/document.pdf"),
  Langchain.root.join("/docs/document.txt"),
  Langchain.root.join("/docs/document.docx")
]

# Add data to the index. Weaviate will use OpenAI to generate embeddings behind the scene.
chroma.add_data(
  paths: docs
)

# Query your data
chroma.similarity_search(
  query: "..."
)

# Interact with your index through Q&A
chroma.ask(
  question: "..."
)
