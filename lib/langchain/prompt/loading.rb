# frozen_string_literal: true

require "strscan"
require "pathname"
require "yaml"

module Langchain::Prompt
  TYPE_TO_LOADER = {
    "prompt" => ->(config) { load_prompt(config) },
    "few_shot" => ->(config) { load_few_shot_prompt(config) }
  }

  module Loading
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      #
      # Load prompt from file.
      #
      # @param file_path [String, Pathname] The path of the file to read the configuration data from.
      #
      # @return [Object] The loaded prompt loaded.
      #
      # @raise [ArgumentError] If the file type of the specified file path is not supported.
      #
      def load_from_path(file_path:)
        file_path = file_path.is_a?(String) ? Pathname.new(file_path) : file_path

        case file_path.extname
        when ".json"
          config = JSON.parse(File.read(file_path))
        when ".yaml", ".yml"
          config = YAML.safe_load_file(file_path)
        else
          raise ArgumentError, "Got unsupported file type #{file_path.extname}"
        end

        load_from_config(config)
      end

      #
      # Loads a prompt template with the given configuration.
      #
      # @param config [Hash] A hash containing the configuration for the prompt.
      #
      # @return [PromptTemplate] The loaded prompt loaded.
      #
      def load_prompt(config)
        template, input_variables = config.values_at("template", "input_variables")
        PromptTemplate.new(template: template, input_variables: input_variables)
      end

      #
      # Loads a prompt template with the given configuration.
      #
      # @param config [Hash] A hash containing the configuration for the prompt.
      #
      # @return [FewShotPromptTemplate] The loaded prompt loaded.
      #
      def load_few_shot_prompt(config)
        prefix, suffix, example_prompt, examples, input_variables = config.values_at("prefix", "suffix", "example_prompt", "examples", "input_variables")
        example_prompt = load_prompt(example_prompt)
        FewShotPromptTemplate.new(prefix: prefix, suffix: suffix, example_prompt: example_prompt, examples: examples, input_variables: input_variables)
      end

      private

      #
      # Loads the prompt from the given configuration hash
      #
      # @param config [Hash] the configuration hash to load from
      #
      # @return [Object] the loaded prompt
      #
      # @raise [ArgumentError] if the prompt type specified in the config is not supported
      #
      def load_from_config(config)
        # If `_type` key is not present in the configuration hash, add it with a default value of `prompt`
        unless config.key?("_type")
          Langchain.logger.warn("#{self.class} - No `_type` key found, defaulting to `prompt`")
          config["_type"] = "prompt"
        end

        # If the prompt type specified in the configuration hash is not supported, raise an exception
        unless TYPE_TO_LOADER.key?(config["_type"])
          raise ArgumentError, "Loading #{config["_type"]} prompt not supported"
        end

        # Load the prompt using the corresponding loader function from the `TYPE_TO_LOADER` hash
        prompt_loader = TYPE_TO_LOADER[config["_type"]]
        prompt_loader.call(config)
      end
    end
  end
end
