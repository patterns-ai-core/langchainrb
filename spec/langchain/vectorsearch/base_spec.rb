# frozen_string_literal: true

RSpec.describe Langchain::Vectorsearch::Base do
  subject { described_class.new(llm_client: Langchain::LLM.build(:openai, "123")) }

  describe "#initialize" do
    it "correctly sets llm_client" do
      expect(
        subject.llm_client
      ).to be_a(Langchain::LLM::OpenAI)
    end
  end

  describe "#create_default_schema" do
    it "raises an error" do
      expect { subject.create_default_schema }.to raise_error(NotImplementedError)
    end
  end

  describe "#add_texts" do
    it "raises an error" do
      expect { subject.add_texts }.to raise_error(NotImplementedError)
    end
  end

  describe "#similarity_search" do
    it "raises an error" do
      expect { subject.similarity_search }.to raise_error(NotImplementedError)
    end
  end

  describe "#similarity_search_by_vector" do
    it "raises an error" do
      expect { subject.similarity_search_by_vector }.to raise_error(NotImplementedError)
    end
  end

  describe "#generate_prompt" do
    it "produces a prompt with the correct format" do
      expect(
        subject.generate_prompt(question: "What is the meaning of life?", context: "41\n42\n43")
      ).to eq <<~PROMPT.chomp
        Context:
        41
        42
        43
        ---
        Question: What is the meaning of life?
        ---
        Answer:
      PROMPT
    end
  end

  describe "#add_data" do
    it "allows adding single path" do
      expect(subject).to receive(:add_texts).with(texts: array_with_strings_matcher(size: 1)) # not sure I love doing this

      subject.add_data(path: Langchain.root.join("../spec/fixtures/loaders/cairo-unicode.pdf"))
    end

    it "allows adding multiple paths" do
      paths = [
        Langchain.root.join("../spec/fixtures/loaders/cairo-unicode.pdf"),
        Langchain.root.join("../spec/fixtures/loaders/clearscan-with-image-removed.pdf"),
        Langchain.root.join("../spec/fixtures/loaders/example.txt")
      ]

      expect(subject).to receive(:add_texts).with(texts: array_with_strings_matcher(size: 3)) # not sure I love doing this

      subject.add_data(paths: paths)
    end

    it "requires path or paths" do
      expect { subject.add_data }.to raise_error(ArgumentError, /Either path or paths must be provided/)
    end

    it "requires only path or paths" do
      expect { subject.add_data(path: [], paths: []) }.to raise_error(ArgumentError, /Either path or paths must be provided, not both/)
    end

    def array_with_strings_matcher(size:)
      proc do |array|
        array.is_a?(Array) &&
          array.length == size &&
          array.all? { |e| e.is_a?(String) }
      end
    end
  end
end
