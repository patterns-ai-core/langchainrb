# frozen_string_literal: true

require "hnswlib"

RSpec.describe Langchain::Vectorsearch::Hnswlib do
  before do
    FileUtils.rm("./test.ann") if File.exist?("./test.ann")
  end

  before do
    allow_any_instance_of(Langchain::LLM::GoogleGemini).to receive(:default_dimensions).and_return(3)
  end

  let(:llm) { Langchain::LLM::GoogleGemini.new(api_key: "123") }
  subject { described_class.new(llm: llm, path_to_index: "./test.ann") }

  describe "#initialize" do
    it "initializes correctly" do
      expect(subject.client).to be_a(Hnswlib::HierarchicalNSW)
      expect(subject.path_to_index).to eq("./test.ann")
      expect(subject.client.max_elements).to eq(100)
    end
  end

  describe "#add_texts" do
    before do
      allow(subject.llm).to receive_message_chain(:embed, :embedding)
        .with(text: "one")
        .with(no_args)
        .and_return([0.1, 0.1, 0.1])
      allow(subject.llm).to receive_message_chain(:embed, :embedding)
        .with(text: "two")
        .with(no_args)
        .and_return([0.2, 0.2, 0.2])
      allow(subject.llm).to receive_message_chain(:embed, :embedding)
        .with(text: "three")
        .with(no_args)
        .and_return([0.3, 0.3, 0.3])
    end

    it "succeeds" do
      expect(subject.client.current_count).to eq(0)
      subject.add_texts(texts: ["one", "two", "three"], ids: [1, 2, 3])
      expect(subject.client.current_count).to eq(3)
    end
  end

  describe "#update_texts" do
    before do
      allow(subject.llm).to receive(:embed) do |text:|
        double(embedding: {"one" => [1.0, 0, 0], "two" => [0, 1.0, 0], "new two" => [0.9, 0.1, 0]}.fetch(text))
      end
      subject.add_texts(texts: ["one", "two"], ids: [1, 2])
    end

    it "replaces the vector stored under an ID" do
      subject.update_texts(texts: ["new two"], ids: [2])

      expect(subject.client.current_count).to eq(2)
      expect(subject.similarity_search_by_vector(embedding: [0.9, 0.1, 0], k: 1).first).to eq([2])
    end

    it "raises without changing the index when an ID is not in it" do
      expect(subject.client).not_to receive(:add_point)

      expect { subject.update_texts(texts: ["new two"], ids: [3]) }.to raise_error(ArgumentError, /3/)
    end
  end

  describe "#remove_texts" do
    before do
      allow(subject.llm).to receive(:embed) do |text:|
        double(embedding: {"one" => [1.0, 0, 0], "two" => [0, 1.0, 0], "three" => [0, 0, 1.0]}.fetch(text))
      end
      subject.add_texts(texts: ["one", "two", "three"], ids: [1, 2, 3])
    end

    it "leaves the removed texts out of searches, also after the index is reloaded" do
      subject.remove_texts(ids: [1, 3])

      expect(subject.similarity_search_by_vector(embedding: [1.0, 0, 0], k: 3).first).to eq([2])

      reloaded = described_class.new(llm: llm, path_to_index: "./test.ann")
      expect(reloaded.similarity_search_by_vector(embedding: [1.0, 0, 0], k: 3).first).to eq([2])
    end

    it "raises without removing anything when an ID is not in the index" do
      expect { subject.remove_texts(ids: [1, 4]) }.to raise_error(ArgumentError, /4/)

      expect(subject.similarity_search_by_vector(embedding: [1.0, 0, 0], k: 3).first).to contain_exactly(1, 2, 3)
    end
  end

  xdescribe "#similarity_search_by_vector" do
  end

  xdescribe "#similarity_search" do
  end

  describe "#resize_index" do
    it "resizes the index" do
      expect(subject.client.max_elements).to eq(100)
      subject.send(:resize_index, 200)
      expect(subject.client.max_elements).to eq(200)
    end

    it "does not resize the index" do
      expect(subject.client.max_elements).to eq(100)
      subject.send(:resize_index, 99)
      expect(subject.client.max_elements).to eq(100)
    end
  end

  describe "#initialize_index" do
    it "initializes the index" do
      expect(subject.client).to receive(:load_index).with("./test.ann")
      allow(File).to receive(:exist?).with("./test.ann").and_return(true)
      subject.send(:initialize_index)
    end

    it "does not initialize the index" do
      expect(subject.client).to receive(:init_index).with(max_elements: 100)
      allow(File).to receive(:exist?).with("./test.ann").and_return(false)
      subject.send(:initialize_index)
    end
  end
end
