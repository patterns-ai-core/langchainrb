# frozen_string_literal: true

module Prompts
  class FewShotPromptTemplate < Base
    attr_reader :examples, :example_prompt, :input_variables, :prefix, :suffix, :example_separator

    def initialize(
      examples:,
      example_prompt:,
      input_variables:,
      suffix:,
      prefix: "",
      example_separator: "\n\n",
      validate_template: true
    )
      @examples = examples
      @example_prompt = example_prompt
      @prefix = prefix
      @suffix = suffix
      @example_separator = example_separator

      validate(template: @prefix + @suffix, input_variables: @input_variables) if @validate_template
    end

    def format(**kwargs)
      example_string = @examples.map { |example| @example_prompt.format(**example) }

      suffix_string = @suffix
      kwargs.each { |key, value| suffix_string = suffix_string.gsub(/\{#{key}\}/, value.to_s) }

      [@prefix, *example_string, suffix_string].join(@example_separator)
    end

    def prompt_type
      "few_shot"
    end
  end
end
