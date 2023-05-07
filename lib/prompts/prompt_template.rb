# frozen_string_literal: true

module Prompts
  class PromptTemplate < Base
    attr_reader :template, :input_variables, :validate_template

    def initialize(template:, input_variables:, validate_template: true)
      @template = template
      @input_variables = input_variables
      @validate_template = validate_template

      validate(template: @template, input_variables: @input_variables) if @validate_template
    end

    def format(**kwargs)
      result = @template
      kwargs.each { |key, value| result = result.gsub(/\{#{key}\}/, value.to_s) }
      result
    end

    def prompt_type
      "prompt"
    end

    def self.from_template(template)
      new(template: template, input_variables: extract_variables_from_template(template))
    end
  end
end
