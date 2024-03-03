# frozen_string_literal: true

require "hnswlib"

RSpec.describe Langchain::Vectorsearch::Hnswlib do
  before do
    FileUtils.rm("./test.ann") if File.exist?("./test.ann")
  end

  before do
    allow_any_instance_of(Langchain::LLM::GooglePalm).to receive(:default_dimension).and_return(3)
  end

  let(:llm) { Langchain::LLM::GooglePalm.new(api_key: "123") }
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
