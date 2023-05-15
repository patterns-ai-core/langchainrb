require "langchain"

# Create a prompt with a few shot examples
prompt = Prompt::FewShotPromptTemplate.new(
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

prompt.format(adjective: "good")

# Write antonyms for the following words.
#
# Input: happy
# Output: sad
#
# Input: tall
# Output: short
#
# Input: good
# Output:

# Save prompt template to JSON file
prompt.save(file_path: "spec/fixtures/prompt/few_shot_prompt_template.json")

# Loading a new prompt template using a JSON file
prompt = Prompt.load_from_path(file_path: "spec/fixtures/prompt/few_shot_prompt_template.json")
prompt.prefix # "Write antonyms for the following words."
