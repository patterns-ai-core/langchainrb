# frozen_string_literal: true

#
# Extends a class to be used as a tool in the assistant.
# A tool is a collection of functions (methods) used to perform specific tasks.
#
# == Usage
#
# 1. Extend your class with {Langchain::ToolDefinition}
# 2. Use {#define_function} to define each function of the tool
#
# == Key Concepts
#
# - {#define_function}: Defines a new function (method) for the tool
# - {ParameterBuilder#property}: Defines properties for the function parameters
# - {ParameterBuilder#item}: Alias for {ParameterBuilder#property}, used for array items
#
# These methods support various data types and nested structures, allowing for flexible and expressive tool definitions.
#
# @example Defining a tool with various property types and configurations
#   define_function :sample_function, description: "Demonstrates various property types and configurations" do
#     property :string_prop, type: "string", description: "A simple string property"
#     property :number_prop, type: "number", description: "A number property"
#     property :integer_prop, type: "integer", description: "An integer property"
#     property :boolean_prop, type: "boolean", description: "A boolean property"
#     property :enum_prop, type: "string", description: "An enum property", enum: ["option1", "option2", "option3"]
#     property :required_prop, type: "string", description: "A required property", required: true
#     property :array_prop, type: "array", description: "An array property" do
#       item type: "string", description: "Array item"
#     end
#     property :object_prop, type: "object", description: "An object property" do
#       property :nested_string, type: "string", description: "Nested string property"
#       property :nested_number, type: "number", description: "Nested number property"
#     end
#   end
#
module Langchain::ToolDefinition
  # Defines a function for the tool
  #
  # @param method_name [Symbol] Name of the method to define
  # @param description [String] Description of the function
  # @yield Block that defines the parameters for the function
  def define_function(method_name, description:, &block)
    function_schemas.add_function(method_name:, description:, &block)
  end

  # Returns the FunctionSchemas instance for this tool
  #
  # @return [FunctionSchemas] The FunctionSchemas instance
  def function_schemas
    @function_schemas ||= FunctionSchemas.new(tool_name)
  end

  # Returns the snake_case version of the class name as the tool's name
  #
  # @return [String] The snake_case version of the class name
  def tool_name
    @tool_name ||= name
      .gsub("::", "_")
      .gsub(/(?<=[A-Z])(?=[A-Z][a-z])|(?<=[a-z\d])(?=[A-Z])/, "_")
      .downcase
  end

  # Manages schemas for functions
  class FunctionSchemas
    def initialize(tool_name)
      @schemas = {}
      @tool_name = tool_name
    end

    # Adds a function to the schemas
    #
    # @param method_name [Symbol] Name of the method to add
    # @param description [String] Description of the function
    # @yield Block that defines the parameters for the function
    # @raise [ArgumentError] If a block is defined and no parameters are specified for the function
    def add_function(method_name:, description:, &block)
      name = "#{@tool_name}__#{method_name}"

      if block_given? # rubocop:disable Performance/BlockGivenWithExplicitBlock
        parameters = ParameterBuilder.new(parent_type: "object").build(&block)

        if parameters[:properties].empty?
          raise ArgumentError, "Function parameters must have at least one property defined within it, if a block is provided"
        end
      end

      @schemas[method_name] = {
        type: "function",
        function: {name:, description:, parameters:}.compact
      }
    end

    # Converts schemas to OpenAI-compatible format
    #
    # @return [String] JSON string of schemas in OpenAI format
    def to_openai_format
      @schemas.values
    end

    # Converts schemas to Anthropic-compatible format
    #
    # @return [String] JSON string of schemas in Anthropic format
    def to_anthropic_format
      @schemas.values.map do |schema|
        # Adds a default input_schema if no parameters are present
        schema[:function][:parameters] ||= {
          type: "object",
          properties: {},
          required: []
        }

        schema[:function].transform_keys(parameters: :input_schema)
      end
    end

    # Converts schemas to Google Gemini-compatible format
    #
    # @return [String] JSON string of schemas in Google Gemini format
    def to_google_gemini_format
      @schemas.values.map { |schema| schema[:function] }
    end
  end

  # Builds parameter schemas for functions
  class ParameterBuilder
    VALID_TYPES = %w[object array string number integer boolean].freeze

    def initialize(parent_type:)
      @schema = (parent_type == "object") ? {type: "object", properties: {}, required: []} : {}
      @parent_type = parent_type
    end

    # Builds the parameter schema
    #
    # @yield Block that defines the properties of the schema
    # @return [Hash] The built schema
    def build(&block)
      instance_eval(&block)
      @schema
    end

    # Defines a property in the schema
    #
    # @param name [Symbol] Name of the property (required only for a parent of type object)
    # @param type [String] Type of the property
    # @param description [String] Description of the property
    # @param enum [Array] Array of allowed values
    # @param required [Boolean] Whether the property is required
    # @yield [Block] Block for nested properties (only for object and array types)
    # @raise [ArgumentError] If any parameter is invalid
    def property(name = nil, type:, description: nil, enum: nil, required: false, &block)
      validate_parameters(name:, type:, enum:, required:)

      prop = {type:, description:, enum:}.compact

      if block_given? # rubocop:disable Performance/BlockGivenWithExplicitBlock
        nested_schema = ParameterBuilder.new(parent_type: type).build(&block)

        case type
        when "object"
          if nested_schema[:properties].empty?
            raise ArgumentError, "Object properties must have at least one property defined within it"
          end
          prop = nested_schema
        when "array"
          if nested_schema.empty?
            raise ArgumentError, "Array properties must have at least one item defined within it"
          end
          prop[:items] = nested_schema
        end
      end

      if @parent_type == "object"
        @schema[:properties][name] = prop
        @schema[:required] << name.to_s if required
      else
        @schema = prop
      end
    end

    # Alias for property method, used for defining array items
    alias_method :item, :property

    private

    # Validates the parameters for a property
    #
    # @param name [Symbol] Name of the property
    # @param type [String] Type of the property
    # @param enum [Array] Array of allowed values
    # @param required [Boolean] Whether the property is required
    # @raise [ArgumentError] If any parameter is invalid
    def validate_parameters(name:, type:, enum:, required:)
      if @parent_type == "object"
        if name.nil?
          raise ArgumentError, "Name must be provided for properties of an object"
        end
        unless name.is_a?(Symbol)
          raise ArgumentError, "Invalid name '#{name}'. Name must be a symbol"
        end
      end

      unless VALID_TYPES.include?(type)
        raise ArgumentError, "Invalid type '#{type}'. Valid types are: #{VALID_TYPES.join(", ")}"
      end

      unless enum.nil? || enum.is_a?(Array)
        raise ArgumentError, "Invalid enum '#{enum}'. Enum must be nil or an array"
      end

      unless [true, false].include?(required)
        raise ArgumentError, "Invalid required '#{required}'. Required must be a boolean"
      end
    end
  end
end
