# frozen_string_literal: true

module LangChain
  module Chunker
    # LLM-powered semantic chunker.
    # Semantic chunking is a technique of splitting texts by their semantic meaning, e.g.: themes, topics, and ideas.
    # We use an LLM to accomplish this. The Anthropic LLM is highly recommended for this task as it has the longest context window (100k tokens).
    #
    # Usage:
    #     LangChain::Chunker::Semantic.new(
    #       text,
    #       llm: LangChain::LLM::Anthropic.new(api_key: ENV["ANTHROPIC_API_KEY"])
    #     ).chunks
    class Semantic < Base
      attr_reader :text, :llm, :prompt_template
      # @param [LangChain::LLM::Base] LangChain::LLM::* instance
      # @param [LangChain::Prompt::PromptTemplate] Optional custom prompt template
      def initialize(text, llm:, prompt_template: nil)
        @text = text
        @llm = llm
        @prompt_template = prompt_template || default_prompt_template
      end

      # @return [Array<LangChain::Chunk>]
      def chunks
        prompt = prompt_template.format(text: text)

        # Replace static 50k limit with dynamic limit based on text length (max_tokens_to_sample)
        completion = llm.complete(prompt: prompt, max_tokens_to_sample: 50000).completion
        completion
          .gsub("Here are the paragraphs split by topic:\n\n", "")
          .split("---")
          .map(&:strip)
          .reject(&:empty?)
          .map do |chunk|
            LangChain::Chunk.new(text: chunk)
          end
      end

      private

      # @return [LangChain::Prompt::PromptTemplate] Default prompt template for semantic chunking
      def default_prompt_template
        LangChain::Prompt.load_from_path(
          file_path: LangChain.root.join("langchain/chunker/prompts/semantic_prompt_template.yml")
        )
      end
    end
  end
end
