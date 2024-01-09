# frozen_string_literal: true

module Langchain::Prompt
  # = Few Shot Prompt Templates
  #
  # Create a prompt with a few shot examples:
  #
  #     prompt = Langchain::Prompt::FewShotPromptTemplate.new(
  #       prefix: "Write antonyms for the following words.",
  #       suffix: "Input: <code>{adjective}</code>\nOutput:",
  #       example_prompt: Langchain::Prompt::PromptTemplate.new(
  #         input_variables: ["input", "output"],
  #         template: "Input: {input}\nOutput: {output}"
  #       ),
  #       examples: [
  #         { "input": "happy", "output": "sad" },
  #         { "input": "tall", "output": "short" }
  #       ],
  #        input_variables: ["adjective"]
  #     )
  #
  #     prompt.format(adjective: "good")
  #
  #     # Write antonyms for the following words.
  #     #
  #     # Input: happy
  #     # Output: sad
  #     #
  #     # Input: tall
  #     # Output: short
  #     #
  #     # Input: good
  #     # Output:
  #
  # Save prompt template to JSON file:
  #
  #     prompt.save(file_path: "spec/fixtures/prompt/few_shot_prompt_template.json")
  #
  # Loading a new prompt template using a JSON file:
  #
  #     prompt = Langchain::Prompt.load_from_path(file_path: "spec/fixtures/prompt/few_shot_prompt_template.json")
  #     prompt.prefix # "Write antonyms for the following words."
  #
  # Loading a new prompt template using a YAML file:
  #
  #     prompt = Langchain::Prompt.load_from_path(file_path: "spec/fixtures/prompt/prompt_template.yaml")
  #     prompt.input_variables #=> ["adjective", "content"]
  #
  class FewShotPromptTemplate < Base
    attr_reader :examples, :example_prompt, :input_variables, :prefix, :suffix, :example_separator

    #
    # Initializes a new instance of the class.
    #
    # @param examples [Array<Hash>] Examples to format into the prompt.
    # @param example_prompt [PromptTemplate] PromptTemplate used to format an individual example.
    # @param suffix [String] A prompt template string to put after the examples.
    # @param input_variables [Array<String>] A list of the names of the variables the prompt template expects.
    # @param example_separator [String] String separator used to join the prefix, the examples, and suffix.
    # @param prefix [String] A prompt template string to put before the examples.
    # @param validate_template [Boolean] Whether or not to try validating the template.
    #
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
      @input_variables = input_variables
      @prefix = prefix
      @suffix = suffix
      @example_separator = example_separator
      @validate_template = validate_template

      validate(template: @prefix + @suffix, input_variables: @input_variables) if @validate_template
    end

    #
    # Format the prompt with the inputs.
    #
    # @param kwargs [Hash] Any arguments to be passed to the prompt template.
    #
    # @return [String] A formatted string.
    #
    def format(**kwargs)
      example_string = @examples.map { |example| @example_prompt.format(**example) }

      suffix_string = @suffix
      kwargs.each { |key, value| suffix_string = suffix_string.gsub(/\{#{key}\}/, value.to_s) }

      [@prefix, *example_string, suffix_string].join(@example_separator)
    end

    #
    # Returns the key type of prompt as a string.
    #
    # @return [String] the prompt type key
    #
    def prompt_type
      "few_shot"
    end

    def to_h
      {
        _type: prompt_type,
        input_variables: @input_variables,
        prefix: @prefix,
        example_prompt: @example_prompt.to_h,
        examples: @examples,
        suffix: @suffix
      }
    end
  end
end
