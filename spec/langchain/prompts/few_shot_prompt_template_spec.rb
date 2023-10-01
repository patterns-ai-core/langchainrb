# frozen_string_literal: true

RSpec.describe Langchain::Prompt::FewShotPromptTemplate do
  let(:input_variables) { ["adjective"] }
  let(:validate_template) { true }
  let(:prompt) do
    described_class.new(
      prefix: "Write antonyms for the following words.",
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
      validate_template: validate_template
    )
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
