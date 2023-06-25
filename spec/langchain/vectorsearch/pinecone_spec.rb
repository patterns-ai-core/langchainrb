# frozen_string_literal: true

require "pinecone"

RSpec.describe Langchain::Vectorsearch::Pinecone do
  let(:index_name) { "documents" }
  let(:namespace) { "namespaced" }

  subject {
    described_class.new(
      environment: "test",
      api_key: "secret",
      index_name: index_name,
      llm: Langchain::LLM::OpenAI.new(api_key: "123")
    )
  }

  describe "#create_default_schema" do
    it "returns true" do
      allow_any_instance_of(Pinecone::Client).to receive(:create_index).with(
        metric: described_class::DEFAULT_METRIC,
        name: index_name,
        dimension: subject.default_dimension
      ).and_return(true)
      expect(subject.create_default_schema).to eq(true)
    end
  end

  let(:text) { "Hello World" }
  let(:embedding) { [0.1, 0.2, 0.3] }
  let(:query) { "Greetings Earth" }
  let(:k) { 4 }
  let(:metadata) do
    {
      "foo" => "bar",
      "meaningful" => "data"
    }
  end
  let(:filter) do
    {
      foo: {"$eq": "bar"}
    }
  end
  let(:matches) do
    [
      {
        "id" => "example-vector-1",
        "score" => 0.08,
        "values" => embedding,
        "metadata" => metadata
      }
    ]
  end

  let(:results) do
    {
      "matches" => matches,
      "namespace" => ""
    }
  end

  describe "add_texts" do
    let(:vectors) do
      [
        {
          id: "123",
          metadata: {content: text},
          values: embedding
        }
      ]
    end

    before do
      allow(SecureRandom).to receive(:uuid).and_return("123")
      allow(subject.llm).to receive(:embed).with(text: text).and_return(embedding)
      allow(subject.client).to receive(:index).with(index_name).and_return(Pinecone::Index.new)
    end

    describe "without a namespace" do
      before(:each) do
        allow_any_instance_of(Pinecone::Index).to receive(:upsert).with(
          vectors: vectors, namespace: ""
        ).and_return(true)
      end

      it "adds texts" do
        expect(subject.add_texts(texts: [text])).to eq(true)
      end
    end

    describe "with a namespace" do
      before(:each) do
        allow_any_instance_of(Pinecone::Index).to receive(:upsert).with(
          vectors: vectors, namespace: namespace
        ).and_return(true)
      end

      it "adds texts" do
        expect(subject.add_texts(texts: [text], namespace: namespace)).to eq(true)
      end
    end

    describe "without a namespace" do
      before(:each) do
        allow_any_instance_of(Pinecone::Index).to receive(:upsert).with(
          vectors: vectors, namespace: ""
        ).and_return(true)
      end

      it "adds texts" do
        expect(subject.add_texts(texts: [text])).to eq(true)
      end
    end

    describe "with supplied metadata" do
      let!(:vectors) do
        [
          {
            id: "123",
            metadata: metadata,
            values: embedding
          }
        ]
      end

      before(:each) do
        allow_any_instance_of(Pinecone::Index).to receive(:upsert).with(
          vectors: vectors, namespace: ""
        ).and_return(true)
      end

      it "adds texts" do
        expect(subject.add_texts(texts: [text], metadata: metadata)).to eq(true)
      end
    end

    describe "with ids" do
      let!(:vectors) do
        [
          {
            id: "456",
            metadata: {content: text},
            values: embedding
          }
        ]
      end

      before(:each) do
        allow_any_instance_of(Pinecone::Index).to receive(:upsert).with(
          vectors: vectors, namespace: ""
        ).and_return(true)
      end

      it "adds texts" do
        expect(subject.add_texts(texts: [text], ids: [456])).to eq(true)
      end
    end
  end

  describe "#update_texts" do
    let(:vectors) do
      [
        {
          id: "123",
          metadata: {content: text},
          values: embedding
        }
      ]
    end

    before do
      vector = double(Pinecone::Vector)
      allow(subject.llm).to receive(:embed).with(text: text).and_return(embedding)
      allow(subject.client).to receive(:index).with(index_name).and_return(vector)
      allow(vector).to receive(:update).with(
        values: embedding, id: "123", namespace: "", set_metadata: nil
      ).and_return(true)
    end

    it "updates texts" do
      expect(subject.update_texts(texts: [text], ids: [123])).to eq([true])
    end
  end

  describe "#similarity_search_by_vector" do
    before do
      allow(subject.llm).to receive(:embed).with(text: text).and_return(embedding)
      allow(subject.client).to receive(:index).with(index_name).and_return(Pinecone::Index.new)
    end

    describe "without a namespace" do
      before(:each) do
        allow_any_instance_of(Pinecone::Index).to receive(:query).with(
          vector: embedding,
          namespace: "",
          top_k: k,
          include_values: true,
          include_metadata: true
        ).and_return(results)
      end

      it "searches for similar texts" do
        expect(subject.similarity_search_by_vector(embedding: embedding)).to be_a(Array)
      end
    end

    describe "with a namespace" do
      before(:each) do
        allow_any_instance_of(Pinecone::Index).to receive(:query).with(
          vector: embedding,
          namespace: namespace,
          top_k: k,
          include_values: true,
          include_metadata: true
        ).and_return(results)
      end

      it "searches for similar texts" do
        expect(subject.similarity_search_by_vector(embedding: embedding, namespace: namespace)).to be_a(Array)
      end
    end

    describe "with a filter" do
      before(:each) do
        allow_any_instance_of(Pinecone::Index).to receive(:query).with(
          vector: embedding,
          namespace: "",
          filter: filter,
          top_k: k,
          include_values: true,
          include_metadata: true
        ).and_return(results)
      end

      it "searches for similar texts" do
        expect(subject.similarity_search_by_vector(embedding: embedding, filter: filter)).to be_a(Array)
      end
    end
  end

  describe "#similarity_search" do
    before do
      allow(subject.llm).to receive(:embed).with(text: query).and_return(embedding)
    end

    describe "without a namespace" do
      before do
        allow(subject).to receive(:similarity_search_by_vector).with(
          embedding: embedding, k: k, namespace: "", filter: nil
        ).and_return(matches)
      end

      it "searches for similar texts" do
        response = subject.similarity_search(query: query, k: k)
        expect(response).to be_a(Array)
        expect(response).to eq(matches)
      end
    end

    describe "with a namespace" do
      before do
        allow(subject).to receive(:similarity_search_by_vector).with(
          embedding: embedding, k: k, namespace: namespace, filter: nil
        ).and_return(matches)
      end

      it "searches for similar texts" do
        response = subject.similarity_search(query: query, k: k, namespace: namespace)
        expect(response).to eq(matches)
      end
    end

    describe "with a filter" do
      before do
        allow(subject).to receive(:similarity_search_by_vector).with(
          embedding: embedding, k: k, namespace: "", filter: filter
        ).and_return(matches)
      end

      it "searches for similar texts" do
        response = subject.similarity_search(query: query, k: k, filter: filter)
        expect(response).to eq(matches)
      end
    end
  end

  describe "#ask" do
    let(:question) { "How many times is \"lorem\" mentioned in this text?" }
    let(:prompt) { "Context:\n#{metadata}\n---\nQuestion: #{question}\n---\nAnswer:" }
    let(:answer) { "5 times" }

    describe "without a namespace" do
      before do
        allow(subject).to receive(:similarity_search).with(
          query: question, namespace: "", filter: nil
        ).and_return(matches)
        allow(subject.llm).to receive(:chat).with(prompt: prompt).and_return(answer)
      end

      it "asks a question" do
        expect(subject.ask(question: question)).to eq(answer)
      end
    end

    describe "with a namespace" do
      before do
        allow(subject).to receive(:similarity_search).with(
          query: question, namespace: namespace, filter: nil
        ).and_return(matches)
        allow(subject.llm).to receive(:chat).with(prompt: prompt).and_return(answer)
      end

      it "asks a question" do
        expect(subject.ask(question: question, namespace: namespace)).to eq(answer)
      end
    end

    describe "with a filter" do
      before do
        allow(subject).to receive(:similarity_search).with(
          query: question, namespace: "", filter: filter
        ).and_return(matches)
        allow(subject.llm).to receive(:chat).with(prompt: prompt).and_return(answer)
      end

      it "asks a question" do
        expect(subject.ask(question: question, filter: filter)).to eq(answer)
      end
    end
  end
end
