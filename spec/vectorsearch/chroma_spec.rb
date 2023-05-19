# frozen_string_literal: true

require "chroma-db"

RSpec.describe Vectorsearch::Chroma do
  let(:index_name) { "documents" }

  subject {
    described_class.new(
      url: "http://localhost:8000",
      index_name: index_name,
      llm: :openai,
      llm_api_key: "123"
    )
  }

  before(:each) do
    allow(Chroma::Resources::Collection).to receive(:get).with(index_name).and_return(collection)
  end

  describe "#create_default_schema" do
    it "returns true" do
      allow(Chroma::Resources::Collection).to receive(:create).with(index_name).and_return(true)
      expect(subject.create_default_schema).to eq(true)
    end
  end

  let(:text) { "Hello World" }
  let(:collection) { Chroma::Resources::Collection.new(name: "documents") }
  let(:embedding) { [0.1, 0.2, 0.3] }
  let(:count) { 1 }
  let(:query) { "Greetings Earth" }
  let(:results) {
    Array(Chroma::Resources::Embedding.new(
      id: SecureRandom.uuid,
      document: text,
      metadata: nil,
      embedding: nil,
      distance: 0.5068268179893494
    ))
  }

  describe "add_texts" do
    before do
      allow(subject.llm_client).to receive(:embed).with(text: text).and_return([0.1, 0.2, 0.3])
      allow_any_instance_of(Chroma::Resources::Collection).to receive(:add).and_return(true)
    end

    it "adds texts" do
      expect(subject.add_texts(texts: [text])).to eq(true)
    end
  end

  describe "#collection" do
    it "returns the collection" do
      expect(subject.send(:collection)).to be_a(Chroma::Resources::Collection)
    end
  end

  describe "#similarity_search_by_vector" do
    before do
      allow_any_instance_of(Chroma::Resources::Collection).to receive(:count).and_return(count)
      allow_any_instance_of(Chroma::Resources::Collection).to receive(:query).with(query_embeddings: [embedding], results: count).and_return(results)
    end

    it "searches for similar texts" do
      expect(subject.similarity_search_by_vector(embedding: embedding).first).to be_a(Chroma::Resources::Embedding)
    end
  end

  describe "#similarity_search" do
    before do
      allow(subject.llm_client).to receive(:embed).with(text: query).and_return(embedding)
      allow(subject).to receive(:similarity_search_by_vector).with(embedding: embedding, k: count).and_return(results)
    end

    it "searches for similar texts" do
      response = subject.similarity_search(query: query, k: count)
      expect(response).to be_a(Array)
      expect(response.first).to be_a(Chroma::Resources::Embedding)
    end
  end

  describe "#ask" do
    let(:question) { "How many times is 'lorem' mentioned in this text?" }
    let(:prompt) { "Context:\n#{text}\n---\nQuestion: #{question}\n---\nAnswer:" }
    let(:answer) { "5 times" }

    before do
      allow(subject).to receive(:similarity_search).with(query: question).and_return(results)
      allow(subject.llm_client).to receive(:chat).with(prompt: prompt).and_return(answer)
    end

    it "asks a question" do
      expect(subject.ask(question: question)).to eq(answer)
    end
  end
end
