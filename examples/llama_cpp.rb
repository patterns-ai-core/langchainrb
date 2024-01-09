require "langchain"
require "dotenv/load"

llm = Langchain::LLM::LlamaCpp.new(
  model_path: ENV["LLAMACPP_MODEL_PATH"],
  n_gpu_layers: Integer(ENV["LLAMACPP_N_GPU_LAYERS"]),
  n_threads: Integer(ENV["LLAMACPP_N_THREADS"])
)

instructions = [
  "Tell me about the creator of Ruby",
  "Write a story about a pony who goes to the store to buy some apples."
]

template = Langchain::Prompt::PromptTemplate.new(
  template: "{instruction}\n\n### Response:",
  input_variables: %w[instruction]
)

instructions.each do |instruction|
  puts "USER: #{instruction}"
  prompt = template.format(instruction: instruction)
  response = llm.complete prompt: prompt, n_predict: 1024
  puts "ASSISTANT: #{response}"
end
