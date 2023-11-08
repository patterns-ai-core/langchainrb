# frozen_string_literal: true

require "milvus"

RSpec.describe Langchain::Vectorsearch::Milvus do
  let(:index_name) { "documents" }

  subject {
    described_class.new(
      url: "http://localhost:8000",
      index_name: index_name,
      llm: Langchain::LLM::OpenAI.new(api_key: "123")
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

  describe "#destroy_default_schema" do
    let(:fixture) { {"result" => true, "status" => "ok", "time" => 0.001313625} }

    before do
      allow(subject.client).to receive_message_chain(:collections, :delete).and_return(fixture)
    end

    it "returns true" do
      expect(subject.destroy_default_schema).to eq(fixture)
    end
  end

  describe "#get_default_schema" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/milvus/get_default_schema.json")) }

    before do
      allow(subject.client).to receive_message_chain(:collections, :get).and_return(fixture)
    end

    it "returns true" do
      expect(subject.get_default_schema).to eq(fixture)
    end
  end

  let(:text) { "Hello World" }
  let(:embedding) { [0.1, 0.2, 0.3] }
  let(:count) { 1 }
  let(:query) { "Greetings Earth" }
  let(:results) {
    {
      "collection_name" => "earthlings",
      "num_rows" => 1,
      "results" => {
        "fields_data" => [
          {
            "field_name" => "content",
            "Field" => {
              "Scalars" => {
                "Data" => {
                  "StringData" => {
                    "data" => ["Hello World"]
                  }
                }
              }
            }
          }, {
            "field_name" => "vectors",
            "type" => ::Milvus::DATA_TYPES["float_vector"],
            "field" => [0, 1, 2]
          }
        ]
      }
    }
  }

  describe "add_texts" do
    before do
      allow(subject.llm).to receive_message_chain(:embed, :embedding).with(text: text).with(no_args).and_return(embedding)
      allow(subject.client).to receive_message_chain(:entities, :insert).and_return(true)
    end

    it "adds texts" do
      expect(subject.add_texts(texts: [text])).to eq(true)
    end
  end

  describe "#similarity_search_by_vector" do
    before do
      allow(subject.client.collections).to receive(:load).and_return(true)
      allow(subject.client).to receive(:search).and_return(true)
    end

    it "searches for similar texts" do
      expect(subject.similarity_search_by_vector(embedding: embedding)).to eq(true)
    end
  end

  describe "#similarity_search" do
    before do
      allow(subject.llm).to receive_message_chain(:embed, :embedding)
        .with(text: query)
        .with(no_args)
        .and_return(embedding)
      allow(subject).to receive(:similarity_search_by_vector).with(embedding: embedding, k: count).and_return(true)
    end

    it "searches for similar texts" do
      response = subject.similarity_search(query: query, k: count)
      expect(response).to eq(true)
    end
  end

  describe "#ask" do
    let(:question) { 'How many times is "lorem" mentioned in this text?' }
    let(:prompt) { "Context:\n#{text}\n---\nQuestion: #{question}\n---\nAnswer:" }
    let(:answer) { "5 times" }
    let(:response) { double(completion: answer) }
    let(:k) { 4 }

    before do
      allow(subject).to receive(:similarity_search).with(query: question, k: k).and_return(results)
    end

    context "without block" do
      before do
        allow(subject.llm).to receive(:chat).with(prompt: prompt).and_return(response)
        expect(response).to receive(:context=).with(text)
      end

      it "asks a question and returns the answer" do
        expect(subject.ask(question: question).completion).to eq(answer)
      end
    end

    context "with block" do
      let(:block) { proc { |chunk| puts "Received chunk: #{chunk}" } }

      before do
        allow(subject.llm).to receive(:chat) do |parameters|
          if parameters[:prompt] == prompt && parameters[:stream].is_a?(Proc)
            parameters[:stream].call("Received chunk from llm.chat")
          end
        end
      end

      it "asks a question and yields the chunk to the block" do
        expect do
          captured_output = capture(:stdout) do
            subject.ask(question: question, &block)
          end
          expect(captured_output).to match(/Received chunk from llm.chat/)
        end
      end
    end
  end
end
