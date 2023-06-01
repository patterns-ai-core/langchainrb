# frozen_string_literal: true

module Langchain::Prompt
  class PromptTemplate < Base
    attr_reader :template, :input_variables, :validate_template

    #
    # Initializes a new instance of the class.
    #
    # @param template [String] The prompt template.
    # @param input_variables [Array<String>] A list of the names of the variables the prompt template expects.
    # @param validate_template [Boolean] Whether or not to try validating the template.
    #
    def initialize(template:, input_variables:, validate_template: true)
      @template = template
      @input_variables = input_variables
      @validate_template = validate_template

      validate(template: @template, input_variables: @input_variables) if @validate_template
    end

    #
    # Format the prompt with the inputs. Double {{}} replaced with single {} to adhere to f-string spec.
    #
    # @param kwargs [Hash] Any arguments to be passed to the prompt template.
    # @return [String] A formatted string.
    #
    def format(**kwargs)
      result = @template
      kwargs.each { |key, value| result = result.gsub(/\{#{key}\}/, value.to_s) }
      result.gsub(/{{/, "{").gsub(/}}/, "}")
    end

    #
    # Returns the key type of prompt as a string.
    #
    # @return [String] the prompt type key
    #
    def prompt_type
      "prompt"
    end

    def to_h
      {
        _type: prompt_type,
        input_variables: @input_variables,
        template: @template
      }
    end

    #
    # Creates a new instance of the class using the given template.
    #
    # @param template [String] The template to use
    #
    # @return [Object] A new instance of the class
    #
    def self.from_template(template)
      new(template: template, input_variables: extract_variables_from_template(template))
    end
  end
end
