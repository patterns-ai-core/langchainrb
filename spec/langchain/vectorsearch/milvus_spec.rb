# frozen_string_literal: true

require "milvus"

RSpec.describe Langchain::Vectorsearch::Milvus do
  let(:index_name) { "documents" }

  subject {
    described_class.new(
      url: "http://localhost:8000",
      index_name: index_name,
      llm: :openai,
      llm_api_key: "123"
    )
  }

  describe "#create_default_schema" do
    before do
      allow(subject.client).to receive_message_chain(:collections, :create).and_return(true)
    end

    it "returns true" do
      expect(subject.create_default_schema).to eq(true)
    end
  end

  let(:text) { "Hello World" }
  let(:embedding) { [0.1, 0.2, 0.3] }
  let(:count) { 1 }
  let(:query) { "Greetings Earth" }

  describe "add_texts" do
    before do
      allow(subject.llm_client).to receive(:embed).with(text: text).and_return(embedding)
      allow(subject.client).to receive_message_chain(:entities, :insert).and_return(true)
    end

    it "adds texts" do
      expect(subject.add_texts(texts: [text])).to eq(true)
    end
  end

  describe "#similarity_search_by_vector" do
    before do
      allow(subject.client).to receive(:search).and_return(true)
    end

    it "searches for similar texts" do
      expect(subject.similarity_search_by_vector(embedding: embedding)).to eq(true)
    end
  end

  describe "#similarity_search" do
    before do
      allow(subject.llm_client).to receive(:embed).with(text: query).and_return(embedding)
      allow(subject).to receive(:similarity_search_by_vector).with(embedding: embedding, k: count).and_return(true)
    end

    it "searches for similar texts" do
      response = subject.similarity_search(query: query, k: count)
      expect(response).to eq(true)
    end
  end

  describe "#ask" do
  end
end
