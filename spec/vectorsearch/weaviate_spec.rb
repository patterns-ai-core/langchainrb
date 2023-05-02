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

  xdescribe "#add_texts"

  xdescribe "#similarity_search"

  xdescribe "#similarity_search_by_vector"

  xdescribe "#ask"
end
