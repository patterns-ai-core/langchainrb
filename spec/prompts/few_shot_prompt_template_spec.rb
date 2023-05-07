# frozen_string_literal: true

RSpec.describe Prompts::FewShotPromptTemplate do
  let!(:prompt) do
    described_class.new(
      prefix: "Write antonyms for the following words.",
      suffix: "Input: {adjective}\nOutput:",
      example_prompt: Prompts::PromptTemplate.new(
        input_variables: ["input", "output"],
        template: "Input: {input}\nOutput: {output}"
      ),
      examples: [
        { "input": "happy", "output": "sad" },
        { "input": "tall", "output": "short" }
      ],
      input_variables: ["adjective"]
    )
  end

  describe "#initialize" do
    it "creates a new instance" do
      expect(prompt).to be_a(Prompts::FewShotPromptTemplate)
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
end
