require "langchain"

llm = Langchain::LLM::LlamaCpp.new(
  model_path: ENV["LLAMACPP_MODEL_PATH"],
  n_gpu_layers: Integer(ENV["LLAMACPP_N_GPU_LAYERS"]),
  n_threads: Integer(ENV["LLAMACPP_N_THREADS"])
)

instruction = "Write a story about a pony who goes to the store to buy some apples."
prompt = "#{instruction}\n\n### Response:"
puts llm.complete prompt: prompt, n_predict: 1024
