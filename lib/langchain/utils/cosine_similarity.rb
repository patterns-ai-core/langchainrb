# frozen_string_literal: true

module Langchain
  module Utils
    class CosineSimilarity
      attr_reader :vector_a, :vector_b

      # @param vector_a [Array<Float>] First vector
      # @param vector_b [Array<Float>] Second vector
      def initialize(vector_a, vector_b)
        @vector_a = vector_a
        @vector_b = vector_b
      end

      # Calculate the cosine similarity between two vectors
      # @return [Float] The cosine similarity between the two vectors
      def calculate_similarity
        return nil unless vector_a.is_a? Array
        return nil unless vector_b.is_a? Array
        return nil if vector_a.size != vector_b.size

        dot_product = 0
        vector_a.zip(vector_b).each do |v1i, v2i|
          dot_product += v1i * v2i
        end

        a = vector_a.map { |n| n**2 }.reduce(:+)
        b = vector_b.map { |n| n**2 }.reduce(:+)

        dot_product / (Math.sqrt(a) * Math.sqrt(b))
      end
    end
  end
end
