# frozen_string_literal: true

RSpec.describe Prompt::FewShotPromptTemplate do
  let!(:prompt) do
    described_class.new(
      prefix: "Write antonyms for the following words.",
      suffix: "Input: {adjective}\nOutput:",
      example_prompt: Prompt::PromptTemplate.new(
        input_variables: ["input", "output"],
        template: "Input: {input}\nOutput: {output}"
      ),
      examples: [
        {input: "happy", output: "sad"},
        {input: "tall", output: "short"}
      ],
      input_variables: ["adjective"]
    )
  end

  describe "#initialize" do
    it "creates a new instance" do
      expect(prompt).to be_a(Prompt::FewShotPromptTemplate)
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
