# frozen_string_literal: true

RSpec.describe Prompts do
  describe "#load_from_path" do
    it "loads a new prompt from file" do
      prompt = Prompts.load_from_path(file_path: "spec/fixtures/prompts/prompt_template.json")
      expect(prompt).to be_a(Prompts::PromptTemplate)
      expect(prompt.input_variables).to eq(["adjective", "content"])
    end

    it "loads a new few shot prompt from file" do
      prompt = Prompts.load_from_path(file_path: "spec/fixtures/prompts/few_shot_prompt_template.json")
      expect(prompt).to be_a(Prompts::FewShotPromptTemplate)
      expect(prompt.example_prompt).to be_a(Prompts::PromptTemplate)
      expect(prompt.prefix).to eq("Write antonyms for the following words.")
    end
  end
end
