# frozen_string_literal: true

require "weaviate"

RSpec.describe Langchain::Vectorsearch::Weaviate do
  subject {
    described_class.new(
      url: "http://localhost:8080",
      api_key: "123",
      index_name: "products",
      llm: Langchain::LLM::OpenAI.new(api_key: "123")
    )
  }

  describe "#create_default_schema" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate/create_default_schema.json")) }

    before do
      allow(subject.client).to receive_message_chain(:schema, :create).and_return(fixture)
    end

    it "creates the default schema" do
      expect(subject.create_default_schema).to eq(fixture)
    end
  end

  describe "#destroy_default_schema" do
    before do
      allow(subject.client).to receive_message_chain(:schema, :delete).and_return(true)
    end

    it "creates the default schema" do
      expect(subject.destroy_default_schema).to eq(true)
    end
  end

  describe "#get_default_schema" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate/get_default_schema.json")) }

    before do
      allow(subject.client).to receive_message_chain(:schema, :get).and_return(fixture)
    end

    it "creates the default schema" do
      expect(subject.get_default_schema).to eq(fixture)
    end
  end

  describe "#add_texts" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate/add_texts.json")) }

    def stub(id)
      allow(
        subject.client.objects
      ).to receive(:batch_create)
        .with(
          objects: [{
            class: "products",
            properties: {__id: id.to_s, content: "Hello World"},
            vector: [-0.0018150936, 0.0017554426, -0.022715086]
          }]
        )
        .and_return(fixture)

      allow(subject.llm).to receive_message_chain(:embed, :embedding)
        .with(text: "Hello World")
        .with(no_args)
        .and_return([
          -0.0018150936,
          0.0017554426,
          -0.022715086
        ])
    end

    context "with ids" do
      before do
        stub(1)
      end

      it "adds texts" do
        expect(subject.add_texts(texts: ["Hello World"], ids: [1])).to eq(fixture)
      end
    end

    context "without ids" do
      before do
        stub(nil)
      end

      it "adds texts" do
        expect(subject.add_texts(texts: ["Hello World"])).to eq(fixture)
      end
    end
  end

  describe "#update_texts" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate/add_texts.json")) }

    let(:record) {
      [{"_additional" => {"id" => "372ba500-01af-4448-aa03-21f3dd25a456"}}]
    }

    before do
      allow(subject.client.query).to receive(:get).and_return(record)

      allow(subject.llm).to receive_message_chain(:embed, :embedding)
        .with(text: "Hello World")
        .with(no_args)
        .and_return([
          -0.0018150936,
          0.0017554426,
          -0.022715086
        ])

      allow(subject.client.objects).to receive(:update).and_return(fixture.first)
    end

    it "updates texts" do
      expect(subject.update_texts(texts: ["Hello World"], ids: [1])).to eq(fixture)
    end
  end

  describe "#similarity_search" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate/search.json")) }

    before do
      allow(
        subject.client.query
      ).to receive(:get)
        .with(
          class_name: "products",
          near_vector: "{ vector: [-0.0018150936, 0.0017554426, -0.022715086] }",
          limit: "4",
          fields: "__id content _additional { id }"
        )
        .and_return(fixture)

      allow(subject.llm).to receive_message_chain(:embed, :embedding)
        .with(text: "earth")
        .with(no_args)
        .and_return([
          -0.0018150936,
          0.0017554426,
          -0.022715086
        ])
    end

    it "searches for similar texts" do
      expect(subject.similarity_search(query: "earth")).to eq(fixture)
    end
  end

  describe "#similarity_search_by_vector" do
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate/search.json")) }

    before do
      allow(
        subject.client.query
      ).to receive(:get)
        .with(
          class_name: "products",
          near_vector: "{ vector: [0.1, 0.2, 0.3] }",
          limit: "4",
          fields: "__id content _additional { id }"
        )
        .and_return(fixture)
    end

    it "searches for similar vectors" do
      expect(subject.similarity_search_by_vector(embedding: [0.1, 0.2, 0.3])).to eq(fixture)
    end
  end

  describe "#ask" do
    let(:matches) { JSON.parse(File.read("spec/fixtures/vectorsearch/weaviate/search.json")) }
    let(:prompt) { "Context:\n#{matches[0]["content"]}\n---\nQuestion: #{question}\n---\nAnswer:" }
    let(:question) { "How many times is \"lorem\" mentioned in this text?" }
    let(:answer) { "5 times" }
    let(:k) { 4 }

    before do
      allow(subject).to receive(:similarity_search).with(
        query: question,
        k: k
      ).and_return(matches)
    end

    context "without block" do
      before do
        allow(subject.llm).to receive(:chat).with(prompt: prompt).and_return(answer)
      end

      it "asks a question and returns the answer" do
        expect(subject.ask(question: question, k: k)).to eq(answer)
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
            subject.ask(question: question, k: k, &block)
          end
          expect(captured_output).to match(/Received chunk from llm.chat/)
        end
      end
    end
  end
end
