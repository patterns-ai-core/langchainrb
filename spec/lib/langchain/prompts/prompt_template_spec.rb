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

    it "raises an error if the template is invalid" do
      expect {
        described_class.new(
          template: prompt_example,
          input_variables: %w[product extra_product],
          validate_template: true
        )
      }.to raise_error(ArgumentError)
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

      prompt = described_class.new(
        template: "Tell me a joke about f-strings and escaping {{json: data}}.",
        input_variables: []
      )

      expect(prompt.format).to eq("Tell me a joke about f-strings and escaping {json: data}.")

      schema = '{"type": "object", "properties": {"setup": {"type": "string"}, "punchline": {"type": "string"}}}'

      prompt = described_class.new(
        template: "Tell me a joke that follows this schema: {schema}",
        input_variables: ["schema"]
      )

      expect(prompt.format(schema: schema)).to eq("Tell me a joke that follows this schema: #{schema}")
    end

    it "keeps escaped braces literal when their content is also a variable name" do
      prompt = described_class.new(template: "Write {{name}} literally, then {name}.", input_variables: ["name"])

      expect(prompt.format(name: "Ada")).to eq("Write {name} literally, then Ada.")
    end

    it "does not expand a variable that appears inside another variable's value" do
      prompt = described_class.new(template: "Question: {question} Context: {context}", input_variables: ["question", "context"])

      expect(prompt.format(question: "what is {context}?", context: "internal notes"))
        .to eq("Question: what is {context}? Context: internal notes")
    end

    it "inserts values with backslashes unchanged" do
      prompt = described_class.new(template: "Code: {code}", input_variables: ["code"])
      code = %q(s = 'It\'s'; re = /\d+/; path = "C:\\Users"; m = "\0\&")

      expect(prompt.format(code: code)).to eq("Code: #{code}")
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
