module Langchain
  module Evals
    module Regex
      class Regex < Base
        attr_reader :regex

        def initialize(regex:)
          @regex = regex
        end

        # Returns the Regex score
        #
        # @param output [String] Output from the LLM model
        # @return [Float] Regex score
        def score(output:)
          output.scan(regex).count ? 1 : 0
        end
      end
    end
  end
end
