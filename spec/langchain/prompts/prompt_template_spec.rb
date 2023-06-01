# frozen_string_literal: true

RSpec.describe Langchain::Prompt::PromptTemplate do
  let!(:prompt_example) do
    <<~PROMPT.chomp
      I want you to act as a naming consultant for new companies.
      What is a good name for a company that makes {product}?
    PROMPT
  end

  describe "#initialize" do
    it "creates a new instance" do
      expect(
        described_class.new(
          template: prompt_example,
          input_variables: ["product"]
        )
      ).to be_a(Langchain::Prompt::PromptTemplate)
    end
  end

  describe "#format" do
    it "creates prompt template" do
      prompt = described_class.new(
        template: prompt_example,
        input_variables: ["product"]
      )

      expect(prompt.format(product: "colorful socks")).to eq(
        <<~PROMPT.chomp
          I want you to act as a naming consultant for new companies.
          What is a good name for a company that makes colorful socks?
        PROMPT
      )

      prompt = described_class.new(
        template: "Tell me a joke.",
        input_variables: []
      )

      expect(prompt.format).to eq("Tell me a joke.")

      prompt = described_class.new(
        template: "Tell me a {adjective} joke.",
        input_variables: ["adjective"]
      )

      expect(prompt.format(adjective: "funny")).to eq("Tell me a funny joke.")

      prompt = described_class.new(
        template: "Tell me a {adjective} joke about {content}.",
        input_variables: ["adjective", "content"]
      )

      expect(prompt.format(adjective: "funny", content: "chickens")).to eq("Tell me a funny joke about chickens.")
    end
  end

  describe "#from_template" do
    it "creates a new instance from given prompt template" do
      prompt = described_class.from_template("Tell me a {adjective} joke about {content}.")
      expect(prompt.input_variables).to eq(["adjective", "content"])
      expect(prompt.format(adjective: "funny", content: "chickens")).to eq("Tell me a funny joke about chickens.")
    end
  end

  describe "#to_h" do
    it "returns Hash representation of prompt template" do
      prompt = described_class.from_template("Tell me a {adjective} joke about {content}.")
      expect(prompt.to_h).to eq({
        _type: "prompt",
        input_variables: ["adjective", "content"],
        template: "Tell me a {adjective} joke about {content}."
      })
    end
  end
end
