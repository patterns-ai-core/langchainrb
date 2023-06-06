# frozen_string_literal: true

RSpec.describe Langchain::Prompt do
  describe "#load_from_path" do
    context "when json file" do
      it "loads a new prompt from file" do
        prompt = described_class.load_from_path(file_path: "spec/fixtures/prompt/prompt_template.json")
        expect(prompt).to be_a(Langchain::Prompt::PromptTemplate)
        expect(prompt.input_variables).to eq(["adjective", "content"])
      end
    end

    context "when yaml file" do
      it "loads a new prompt from file" do
        prompt = described_class.load_from_path(file_path: "spec/fixtures/prompt/prompt_template.yaml")
        expect(prompt).to be_a(Langchain::Prompt::PromptTemplate)
        expect(prompt.input_variables).to eq(["adjective", "content"])
      end
    end

    it "loads a new few shot prompt from file" do
      prompt = described_class.load_from_path(file_path: "spec/fixtures/prompt/few_shot_prompt_template.json")
      expect(prompt).to be_a(Langchain::Prompt::FewShotPromptTemplate)
      expect(prompt.example_prompt).to be_a(Langchain::Prompt::PromptTemplate)
      expect(prompt.prefix).to eq("Write antonyms for the following words.")
    end
  end
end
