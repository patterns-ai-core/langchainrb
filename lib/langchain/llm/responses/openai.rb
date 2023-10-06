# frozen_string_literal: true

module Langchain::LLM::Responses::OpenAI
  def self.parse(response, type: nil)
    Langchain::LLM::Response.new({
      provider: :openai,
      type: type || get_type(response),
      model: response.dig("model"),
      values: is_embedding?(response) ? embeddings(response) : completions(response),
      error: response.dig("error"),
      prompt_tokens: response.dig("usage", "prompt_tokens"),
      completion_tokens: response.dig("usage", "completion_tokens"),
      total_tokens: response.dig("usage", "total_tokens")
    })
  end

  def self.get_type(response)
    return "embedding" if is_embedding?(response)

    response.dig("object")
  end

  def self.completions(response)
    response.dig("choices").map { |choice| choice.dig("message") }
  end

  def self.embeddings(response)
    response.dig("data").map { |datum| datum.dig("embedding") }
  end

  def self.is_embedding?(response)
    response.dig("object") == "list"
  end
end
