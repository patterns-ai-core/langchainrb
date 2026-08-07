# frozen_string_literal: true

require "langchain"
require "dotenv/load"
require "ruby/openai"

# This example assumes you are running Elasticsearch in Docker:
#
#   docker run --name es8 -d \
#     -p 9200:9200 -p 9300:9300 \
#     -e "discovery.type=single-node" \
#     -e "xpack.security.enabled=false" \
#     docker.elastic.co/elasticsearch/elasticsearch:8.12.2
#
# The container exposes the REST API on http://localhost:9200 which
# the script connects to below. If you use a different host/port, set
# the ELASTICSEARCH_URL environment variable accordingly before running
# the script:
#   ELASTICSEARCH_URL=http://localhost:9201 ruby examples/...

# Instantiate the Elasticsearch vector store
es = Langchain::Vectorsearch::Elasticsearch.new(
  url: ENV.fetch("ELASTICSEARCH_URL", "http://localhost:9200"),
  index_name: "documents",
  llm: Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
)

# Create the index & mapping (safe to call if it already exists)
# You may need to delete an old index first if it was created without the metadata field.
begin
  es.create_default_schema
rescue => e
  warn "Index might already exist: #{e.message}"
end

# Prepare documents with metadata
corpus = [
  {
    text: "Vector search lets you retrieve semantically similar documents.",
    metadata: {lang: "en", author: "alice", topic: "vector-search"}
  },
  {
    text: "Las bases de datos vectoriales permiten búsquedas semánticas.",
    metadata: {lang: "es", author: "bob", topic: "vector-search"}
  },
  {
    text: "Ruby makes metaprogramming accessible and fun.",
    metadata: {lang: "en", author: "carol", topic: "ruby"}
  }
]

puts "\nAdding documents with metadata …"

es.add_texts(
  texts: corpus.map { |d| d[:text] },
  metadatas: corpus.map { |d| d[:metadata] }
)

sleep 1 # give ES a moment to index

puts "\nSimilarity search for 'vector' restricted to English docs:"
filter = {term: {"metadata.lang" => "en"}}
results = es.similarity_search(text: "vector", k: 2, filter: filter)
pp results

puts "\nSimilarity search by embedding, Spanish docs only:"
embedding = es.llm.embed(text: "vector query").embedding
filter = {term: {"metadata.lang" => "es"}}
pp es.similarity_search_by_vector(embedding: embedding, k: 1, filter: filter)

# Cleanup (optional)
# es.delete_default_schema
