# frozen_string_literal: true

RSpec.describe Langchain::Prompt::FewShotPromptTemplate do
  let(:input_variables) { ["adjective"] }
  let(:prefix) { "Write antonyms for the following words." }
  let(:example_separator) { "\n\n" }
  let(:validate_template) { true }
  let(:prompt) do
    described_class.new(
      prefix: prefix,
      suffix: "Input: {adjective}\nOutput:",
      example_prompt: Langchain::Prompt::PromptTemplate.new(
        input_variables: ["input", "output"],
        template: "Input: {input}\nOutput: {output}"
      ),
      examples: [
        {input: "happy", output: "sad"},
        {input: "tall", output: "short"}
      ],
      input_variables: input_variables,
      example_separator: example_separator,
      validate_template: validate_template
    )
  end

  describe "#format with prefix variables" do
    let(:prefix) { "Topic: {topic}" }
    let(:input_variables) { ["topic", "adjective"] }

    it "substitutes variables used only by the prefix" do
      expect(prompt.format(topic: "Ruby", adjective: "good")).to start_with("Topic: Ruby\n\nInput: happy")
    end

    it "keeps inserted braces and backslashes as data in one pass" do
      value = %q(It\'s {adjective} \0)
      formatted = prompt.format(topic: value, adjective: "good")
      expect(formatted).to start_with("Topic: #{value}\n\n")
      expect(formatted).to end_with("Input: good\nOutput:")
      expect(prompt.prefix).to eq("Topic: {topic}")
    end

    it "accepts string argument keys in the prefix too" do
      expect(prompt.format(**{"topic" => "Ruby", "adjective" => "good"})).to start_with("Topic: Ruby\n\n")
    end

    context "when a variable is shared with the suffix" do
      let(:prefix) { "Word: {adjective}" }
      let(:input_variables) { ["adjective"] }
      let(:example_separator) { " | " }

      it "formats both ends while retaining examples and the custom separator" do
        expect(prompt.format(adjective: "good")).to eq("Word: good | Input: happy\nOutput: sad | Input: tall\nOutput: short | Input: good\nOutput:")
      end
    end

    context "when an unknown prefix variable is allowed" do
      let(:prefix) { "Keep {missing}" }
      let(:input_variables) { ["adjective"] }
      let(:validate_template) { false }

      it "preserves the unknown placeholder" do
        expect(prompt.format(adjective: "good")).to start_with("Keep {missing}\n\n")
      end
    end

    ["{{adjective}}", "{{{adjective}}}", "{{adjective}"].each do |literal|
      context "when the prefix contains the literal #{literal}" do
        let(:prefix) { "Literal: #{literal}" }
        let(:input_variables) { ["adjective"] }

        it "keeps the prefix region ignored by variable extraction unchanged" do
          expect(prompt.format(adjective: "good")).to start_with("Literal: #{literal}\n\n")
        end
      end
    end

    context "when variable extraction trims whitespace" do
      let(:prefix) { "Topic: { topic }" }

      it "formats the variable accepted by validation" do
        expect(prompt.format(topic: "Ruby", adjective: "good")).to start_with("Topic: Ruby\n\n")
      end
    end

    context "when whitespace precedes an ignored brace region" do
      let(:prefix) { "Literal: { {adjective}}" }
      let(:input_variables) { ["adjective"] }

      it "keeps that region literal as variable extraction does" do
        expect(prompt.format(adjective: "good")).to start_with("Literal: { {adjective}}\n\n")
      end
    end
  end

  describe "#initialize" do
    it "creates a new instance" do
      expect(prompt).to be_a(Langchain::Prompt::FewShotPromptTemplate)
      expect(prompt.format(adjective: "good")).to eq(
        <<~PROMPT.chomp
          Write antonyms for the following words.

          Input: happy
          Output: sad

          Input: tall
          Output: short

          Input: good
          Output:
        PROMPT
      )
    end

    it "inserts a suffix value with backslashes or braces unchanged" do
      value = %q(It\'s {adjective} \0)

      expect(prompt.format(adjective: value)).to end_with("Input: #{value}\nOutput:")
    end

    context "input_variables is invalid" do
      let(:input_variables) { ["adjective", "extra_adjective"] }

      context "when validate template is true" do
        let(:validate_template) { true }

        it "raises an error if the template is invalid" do
          expect { prompt }.to raise_error(ArgumentError)
        end
      end

      context "when validate template is false" do
        let(:validate_template) { false }

        it "does not raise an error" do
          expect { prompt }.not_to raise_error
        end
      end
    end
  end

  describe "#to_h" do
    it "returns Hash representation of prompt template" do
      expect(prompt.to_h).to eq({
        _type: "few_shot",
        input_variables: ["adjective"],
        prefix: "Write antonyms for the following words.",
        example_prompt: {
          _type: "prompt",
          input_variables: ["input", "output"],
          template: "Input: {input}\nOutput: {output}"
        },
        examples: [
          {input: "happy", output: "sad"},
          {input: "tall", output: "short"}
        ],
        suffix: "Input: {adjective}\nOutput:"
      })
    end
  end
end
