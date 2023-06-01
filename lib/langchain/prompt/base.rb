# frozen_string_literal: true

require "strscan"
require "json"

module Langchain::Prompt
  class Base
    def format(**kwargs)
      raise NotImplementedError
    end

    def prompt_type
      raise NotImplementedError
    end

    def to_h
      raise NotImplementedError
    end

    #
    # Validate the input variables against the template.
    #
    # @param template [String] The template to validate against.
    # @param input_variables [Array<String>] The input variables to validate.
    #
    # @raise [ArgumentError] If there are missing or extra variables.
    #
    # @return [void]
    #
    def validate(template:, input_variables:)
      input_variables_set = @input_variables.uniq
      variables_from_template = Langchain::Prompt::Base.extract_variables_from_template(template)

      missing_variables = variables_from_template - input_variables_set
      extra_variables = input_variables_set - variables_from_template

      raise ArgumentError, "Missing variables: #{missing_variables}" if missing_variables.any?
      raise ArgumentError, "Extra variables: #{extra_variables}" if extra_variables.any?
    end

    #
    # Save the object to a file in JSON format.
    #
    # @param file_path [String, Pathname] The path to the file to save the object to
    #
    # @raise [ArgumentError] If file_path doesn't end with .json
    #
    # @return [void]
    #
    def save(file_path:)
      save_path = file_path.is_a?(String) ? Pathname.new(file_path) : file_path
      directory_path = save_path.dirname
      FileUtils.mkdir_p(directory_path) unless directory_path.directory?

      if save_path.extname == ".json"
        File.write(file_path, to_h.to_json)
      else
        raise ArgumentError, "#{file_path} must be json"
      end
    end

    #
    # Extracts variables from a template string.
    #
    # This method takes a template string and returns an array of input variable names
    # contained within the template. Input variables are defined as text enclosed in
    # curly braces (e.g. "{variable_name}").
    #
    # Content within two consecutive curly braces (e.g. "{{ignore_me}}) are ignored.
    #
    # @param template [String] The template string to extract variables from.
    #
    # @return [Array<String>] An array of input variable names.
    #
    def self.extract_variables_from_template(template)
      input_variables = []
      scanner = StringScanner.new(template)

      while scanner.scan_until(/\{([^}]*)\}/)
        variable = scanner[1].strip
        input_variables << variable unless variable.empty? || variable[0] == "{"
      end

      input_variables
    end
  end
end
