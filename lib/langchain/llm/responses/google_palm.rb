# frozen_string_literal: true

module Langchain::LLM::Responses::GooglePalm
  def self.parse(response, type:, model:, prompt_tokens: nil, completion_tokens: nil, total_tokens: nil)
    Langchain::LLM::Response.new({
      provider: :google_palm,
      type: type,
      model: model,
      values: values_by_type(type, response),
      error: response.dig("error"),
      prompt_tokens: prompt_tokens,
      completion_tokens: completion_tokens,
      total_tokens: total_tokens
    })
  end

  def self.values_by_type(type, response)
    case type
    when "completion"
      completions(response)
    when "chat.completion"
      chat_completions(response)
    when "embedding"
      embeddings(response)
    end
  end

  def self.chat_completions(response)
    response.dig("candidates").map do |candidate|
      {"role" => candidate.dig("author"), "content" => candidate.dig("content")}
    end
  end

  def self.completions(response)
    response.dig("candidates").map do |candidate|
      {"role" => "assystant", "content" => candidate.dig("output")}
    end
  end

  def self.embeddings(response)
    [response.dig("embedding", "value")]
  end
end
