# frozen_string_literal: true

require 'strscan'
require 'pathname'

module Prompts
  TYPE_TO_LOADER = {
    "prompt" => ->(config) { Prompts.load_prompt(config) },
    "few_shot" => ->(config) { Prompts.load_few_shot_prompt(config) }
  }

  class << self
    def load_from_path(file_path:)
      file_path = file_path.is_a?(String) ? Pathname.new(file_path) : file_path

      if file_path.extname == ".json"
        config = JSON.parse(File.read(file_path))
      else
        raise ArgumentError, "Got unsupported file type #{file_path.extname}"
      end

      load_from_config(config)
    end

    def load_prompt(config)
      template, input_variables = config.values_at("template", "input_variables")
      PromptTemplate.new(template: template, input_variables: input_variables)
    end

    def load_few_shot_prompt(config)
      prefix, suffix, example_prompt, examples, input_variables = config.values_at("prefix", "suffix", "example_prompt", "examples", "input_variables")
      example_prompt = load_prompt(example_prompt)
      FewShotPromptTemplate.new(prefix: prefix, suffix: suffix, example_prompt: example_prompt, examples: examples, input_variables: input_variables)
    end

    private

    def load_from_config(config)
      unless config.key?("_type")
        puts "[WARN] No `_type` key found, defaulting to `prompt`"
        config["_type"] = "prompt"
      end

      unless TYPE_TO_LOADER.key?(config["_type"])
        raise ArgumentError, "Loading #{config["_type"]} prompt not supported"
      end

      prompt_loader = TYPE_TO_LOADER[config["_type"]]
      prompt_loader.call(config)
    end
  end
end
