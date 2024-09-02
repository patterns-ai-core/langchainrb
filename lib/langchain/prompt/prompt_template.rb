# frozen_string_literal: true

module Langchain::Prompt
  # = Prompt Templates
  #
  # Create a prompt with one input variable:
  #
  #     prompt = Langchain::Prompt::PromptTemplate.new(template: "Tell me a {adjective} joke.", input_variables: ["adjective"])
  #     prompt.format(adjective: "funny") # "Tell me a funny joke."
  #
  # Create a prompt with multiple input variables:
  #
  #     prompt = Langchain::Prompt::PromptTemplate.new(template: "Tell me a {adjective} joke about {content}.", input_variables: ["adjective", "content"])
  #     prompt.format(adjective: "funny", content: "chickens") # "Tell me a funny joke about chickens."
  #
  # Creating a PromptTemplate using just a prompt and no input_variables:
  #
  #     prompt = Langchain::Prompt::PromptTemplate.from_template("Tell me a {adjective} joke about {content}.")
  #     prompt.input_variables # ["adjective", "content"]
  #     prompt.format(adjective: "funny", content: "chickens") # "Tell me a funny joke about chickens."
  #
  # Save prompt template to JSON file:
  #
  #     prompt.save(file_path: "spec/fixtures/prompt/prompt_template.json")
  #
  # Loading a new prompt template using a JSON file:
  #
  #     prompt = Langchain::Prompt.load_from_path(file_path: "spec/fixtures/prompt/prompt_template.json")
  #     prompt.input_variables # ["adjective", "content"]
  #
  # Loading a new prompt template using a YAML file:
  #     prompt = Langchain::Prompt.load_from_path(file_path: "spec/fixtures/prompt/prompt_template.yaml")
  #     prompt.input_variables #=> ["adjective", "content"]
  #
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
    # Format the prompt with the inputs. Double <code>{{}}</code> replaced with single <code>{}</code> to adhere to f-string spec.
    #
    # @param kwargs [Hash] Any arguments to be passed to the prompt template.
    # @return [String] A formatted string.
    #
    def format(**kwargs)
      result = @template
      result = result.gsub(/{{/, "{").gsub(/}}/, "}")
      kwargs.each { |key, value| result = result.gsub(/\{#{key}\}/, value.to_s) }
      result
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
