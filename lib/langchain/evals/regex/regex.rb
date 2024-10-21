module Langchain
  module Evals
    module Regex
      class Regex < Base
        attr_reader :regex, :attributes

        VALID_ATTRIBUTES = %i[question answer context].freeze

        def initialize(regex:, attributes: [:answer], combinator: :and)
          unless attributes.all? { |attr| VALID_ATTRIBUTES.include?(attr) }
            raise ArgumentError, "attributes can only include :question, :answer, and :context"
          end

          @attributes = attributes

          @regex = regex
        end

        # Returns the Regex score
        #
        # @param answer [String] Output
        # @param question [String] Question
        # @param context [String] Context
        # @return [Float] Regex score
        def score(question: nil, answer: nil, context: nil, expected_answer: nil)
          args = {question: question, answer: answer, context: context, expected_answer: expected_answer}

          interpolated_regex = regex.source.gsub(/%\{(\w+)\}/) do |match|
            args[match[2..-2].to_sym]
          end

          (attributes.map do |attr|
            args[attr]
          end.join(" ").scan(interpolated_regex).size > 0) ? 1 : 0
        end
      end
    end
  end
end
