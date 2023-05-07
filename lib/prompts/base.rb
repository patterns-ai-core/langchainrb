# frozen_string_literal: true

require 'strscan'

module Prompts
  class Base
    def format(**kwargs)
      raise NotImplementedError
    end

    def prompt_type
      raise NotImplementedError
    end

    def to_h
      {
        _type: prompt_type,
        input_variables: @input_variables,
        template: @template
      }
    end

    def validate(template:, input_variables:)
      input_variables_set = @input_variables.uniq
      variables_from_template = Prompts::Base.extract_variables_from_template(template)

      missing_variables = variables_from_template - input_variables_set
      extra_variables = input_variables_set - variables_from_template

      raise ArgumentError, "Missing variables: #{missing_variables}" if missing_variables.any?
      raise ArgumentError, "Extra variables: #{extra_variables}" if extra_variables.any?
    end

    def save(file_path:)
      save_path = file_path.is_a?(String) ? Pathname.new(file_path) : file_path
      directory_path = save_path.dirname
      FileUtils.mkdir_p(directory_path) unless directory_path.directory?

      if save_path.extname == ".json"
        File.open(file_path, "w") { |f| f.write(to_h.to_json) }
      else
        raise ArgumentError, "#{file_path} must be json"
      end
    end

    private

    def self.extract_variables_from_template(template)
      input_variables = []
      scanner = StringScanner.new(template)

      while scanner.scan_until(/\{([^{}]*)\}/)
        variable = scanner[1].strip
        input_variables << variable unless variable.empty?
      end

      input_variables
    end
  end
end
