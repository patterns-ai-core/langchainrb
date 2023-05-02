# frozen_string_literal: true

RSpec.describe Vectorsearch::Weaviate do
  subject {
    described_class.new(
      url: "http://localhost:8080",
      api_key: "123",
      index_name: "products",
      llm: :openai,
      llm_api_key: "123"
    )
  }

  describe "#create_default_schema" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate_create_default_schema.json")) }

    before do
      allow_any_instance_of(Weaviate::Client).to receive_message_chain(:schema, :create).and_return(fixture)
    end

    it "creates the default schema" do
      expect(subject.create_default_schema).to eq(fixture)
    end
  end

  describe "#add_texts" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate_add_texts.json")) }

    before do
      allow_any_instance_of(
        Weaviate::Objects
      ).to receive(:batch_create)
      .with(
        objects: [{
          class: "products",
          properties: { content: "Hello World" }
        }]
      )
      .and_return(fixture)
    end

    it "adds texts" do
      expect(subject.add_texts(texts: ["Hello World"])).to eq(fixture)
    end

  end

  describe "#similarity_search" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate_search.json")) }

    before do
      allow_any_instance_of(
        Weaviate::Query
      ).to receive(:get)
      .with(
        class_name: "products",
        near_text: "{ concepts: [\"earth\"] }",
        limit: "4",
        fields: "content _additional { id }"
      )
      .and_return(fixture)
    end

    it "searches for similar texts" do
      expect(subject.similarity_search(query: "earth")).to eq(fixture)
    end
  end

  describe "#similarity_search_by_vector" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate_search.json")) }

    before do
      allow_any_instance_of(
        Weaviate::Query
      ).to receive(:get)
      .with(
        class_name: "products",
        near_vector: "{ vector: [0.1, 0.2, 0.3] }",
        limit: "4",
        fields: "content _additional { id }"
      )
      .and_return(fixture)
    end

    it "searches for similar vectors" do
      expect(subject.similarity_search_by_vector(embedding: [0.1, 0.2, 0.3])).to eq(fixture)
    end
  end

  xdescribe "#ask"
end
