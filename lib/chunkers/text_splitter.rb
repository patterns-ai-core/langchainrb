# frozen_string_literal: true

module Chunkers
  class TextSplitter < Base
    def initialize(delimeter: "\n\n", delimeter_function: nil, **kwargs)
      super(**kwargs)

      @delimeter = delimeter
      @delimeter_function = delimeter_function
    end

    def split_text(text)
      basic_split = text.split(delimeter)

      if delimeter_function
        chunks = [[]]
        index = 0
        basic_split
          .each do |line|
            index += 1 if delimeter_function.call(line)

            chunks[index] ||= []
            chunks[index] << line
          end

        basic_split = chunks.keep_if(&:any?).map { |chunk| chunk.join(delimeter) }
      end

      basic_split
    end

    attr_reader :delimeter, :delimeter_function
  end
end
