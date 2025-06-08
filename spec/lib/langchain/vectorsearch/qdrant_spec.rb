# frozen_string_literal: true

require "qdrant"

RSpec.describe Langchain::Vectorsearch::Qdrant do
  let(:index_name) { "documents" }

  subject {
    described_class.new(
      url: "http://localhost:8000",
      index_name: index_name,
      api_key: "secret",
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
    let(:fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/qdrant/get_default_schema.json")) }

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

  describe "#find" do
    let(:points_fixture) { JSON.parse(File.read("spec/fixtures/vectorsearch/qdrant/points.json")) }

    before do
      allow(subject.client).to receive_message_chain(:points, :get_all).and_return(points_fixture)
    end

    it "searches for similar texts" do
      expect(subject.find(ids: [4, 1, 2, 5, 6]).dig("result").count).to eq(5)
    end
  end

  describe "add_texts" do
    before do
      allow(subject.llm).to receive_message_chain(:embed, :embedding).with(text: text).with(no_args).and_return(embedding)
      allow(subject.client).to receive_message_chain(:points, :upsert).and_return(true)
    end

    it "adds texts" do
      expect(subject.add_texts(texts: [text], ids: [1])).to eq(true)
    end

    context "when merging provided payload with default payload" do
      let(:provided_payload) { {author: "Test Author", extra: "Extra Data"} }
      let(:expected_payload) { [{content: text}.merge(provided_payload)] }

      it "merges provided payload into default" do
        expect(subject.client.points).to receive(:upsert).with(
          hash_including(
            batch: hash_including(
              payloads: expected_payload
            )
          )
        ).and_return(true)

        result = subject.add_texts(texts: [text], ids: [1], payload: provided_payload)
        expect(result).to eq(true)
      end
    end
  end

  describe "updates_texts" do
    it "adds texts" do
      expect(subject).to receive(:add_texts).with(texts: [text], ids: [1]).and_return(true)
      subject.update_texts(texts: [text], ids: [1])
    end
  end

  describe "remove_texts" do
    before do
      allow(subject.client).to receive_message_chain(:points, :delete).and_return(true)
    end

    it "removes texts" do
      expect(subject.remove_texts(ids: [1])).to eq(true)
    end
  end

  describe "#similarity_search_by_vector" do
    before do
      allow(subject.client).to receive_message_chain(:points, :search).and_return(
        {"result" => [{}]}
      )
    end

    it "searches for similar texts" do
      expect(subject.similarity_search_by_vector(embedding: embedding)).to eq([{}])
    end
  end

  describe "#similarity_search" do
    before do
      allow(subject.llm).to receive_message_chain(:embed, :embedding).with(text: query).with(no_args).and_return(embedding)
      allow(subject).to receive(:similarity_search_by_vector).with(embedding: embedding, k: count).and_return(true)
    end

    it "searches for similar texts" do
      response = subject.similarity_search(query: query, k: count)
      expect(response).to eq(true)
    end
  end

  describe "#ask" do
    let(:question) { "How many times is 'lorem' mentioned in this text?" }
    let(:messages) { [{role: "user", content: "Context:\n#{text}\n---\nQuestion: #{question}\n---\nAnswer:"}] }
    let(:response) { double(completion: answer) }
    let(:answer) { "5 times" }
    let(:k) { 4 }

    before do
      allow(subject).to receive(:similarity_search).with(query: question, k: k).and_return([{"payload" => text}])
    end

    context "without block" do
      before do
        allow(subject.llm).to receive(:chat).with(messages: messages).and_return(response)
        expect(response).to receive(:context=).with(text)
      end

      it "asks a question and returns the answer" do
        expect(subject.ask(question: question, k: k).completion).to eq(answer)
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
