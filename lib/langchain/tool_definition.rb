# frozen_string_literal: true

require "json"

module Langchain::ToolDefinition
  # Defines an action for the tool
  #
  # @param method_name [Symbol] Name of the method to define
  # @param description [String] Description of the action
  # @yield Block that defines the parameters for the action
  def define_action(method_name, description:, &)
    action_schemas.add_action(method_name:, description:, &)
  end

  # Returns the ActionSchemas instance for this tool
  #
  # @return [ActionSchemas] The ActionSchemas instance
  def action_schemas
    @action_schemas ||= ActionSchemas.new(tool_name)
  end

  # Returns the snake_case version of the class name as the tool's name
  #
  # @return [String] The snake_case version of the class name
  def tool_name
    @tool_name ||= name.gsub(/([A-Z])/, '_\1').gsub(/^_/, "").gsub("::", "").downcase
  end

  # Manages schemas for actions
  class ActionSchemas
    def initialize(tool_name)
      @schemas = {}
      @tool_name = tool_name
    end

    # Adds an action to the schemas
    #
    # @param method_name [Symbol] Name of the method to add
    # @param description [String] Description of the action
    # @yield Block that defines the parameters for the action
    # @raise [ArgumentError] If a block is defined and no parameters are specified for the action
    def add_action(method_name:, description:, &)
      name = "#{@tool_name}__#{method_name}"

      if block_given?
        parameters = ParameterBuilder.new(parent_type: "object").build(&)

        if parameters.empty?
          raise ArgumentError, "Action parameters must have at least one property defined within it, if a block is provided"
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
        schema[:function].transform_keys("parameters" => "input_schema")
      end
    end

    # Converts schemas to Google Gemini-compatible format
    #
    # @return [String] JSON string of schemas in Google Gemini format
    def to_google_gemini_format
      @schemas.values.map { |schema| schema[:function] }
    end
  end

  # Builds parameter schemas for actions
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
    def build(&)
      instance_eval(&)
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
    def property(name = nil, type:, description: nil, enum: nil, required: false, &)
      validate_parameters(name:, type:, enum:, required:)

      prop = {type:, description:, enum:}.compact

      if block_given?
        nested_schema = ParameterBuilder.new(parent_type: type).build(&)

        case type
        when "object"
          if nested_schema.empty?
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
