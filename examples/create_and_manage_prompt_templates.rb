require "langchain"

# Create a prompt with one input variable
prompt = Prompt::PromptTemplate.new(template: "Tell me a {adjective} joke.", input_variables: ["adjective"])
prompt.format(adjective: "funny") # "Tell me a funny joke."

# Create a prompt with multiple input variables
prompt = Prompt::PromptTemplate.new(template: "Tell me a {adjective} joke about {content}.", input_variables: ["adjective", "content"])
prompt.format(adjective: "funny", content: "chickens") # "Tell me a funny joke about chickens."

# Creating a PromptTemplate using just a prompt and no input_variables
prompt = Prompt::PromptTemplate.from_template("Tell me a {adjective} joke about {content}.")
prompt.input_variables # ["adjective", "content"]
prompt.format(adjective: "funny", content: "chickens") # "Tell me a funny joke about chickens."

# Save prompt template to JSON file
prompt.save(file_path: "spec/fixtures/prompt/prompt_template.json")

# Loading a new prompt template using a JSON file
prompt = Prompt.load_from_path(file_path: "spec/fixtures/prompt/prompt_template.json")
prompt.input_variables # ["adjective", "content"]
