# frozen_string_literal: true

require "json-schema"

module Langchain::OutputParsers
  # = Structured Output Parser
  class StructuredOutputParser < Base
    attr_reader :schema

    # Initializes a new instance of the class.
    #
    # @param schema [JSON::Schema] The json schema
    def initialize(schema:)
      @schema = validate_schema!(schema)
    end

    def to_h
      {
        _type: "StructuredOutputParser",
        schema: schema.to_json
      }
    end

    # Creates a new instance of the class using the given JSON::Schema.
    #
    # @param schema [JSON::Schema] The JSON::Schema to use
    #
    # @return [Object] A new instance of the class
    def self.from_json_schema(schema)
      new(schema: schema)
    end

    # Returns a string containing instructions for how the output of a language model should be formatted
    # according to the @schema.
    #
    # @return [String] Instructions for how the output of a language model should be formatted
    # according to the @schema.
    def get_format_instructions
      <<~INSTRUCTIONS
        You must format your output as a JSON value that adheres to a given "JSON Schema" instance.

        "JSON Schema" is a declarative language that allows you to annotate and validate JSON documents.

        For example, the example "JSON Schema" instance {"properties": {"foo": {"description": "a list of test words", "type": "array", "items": {"type": "string"}}}, "required": ["foo"]}}
        would match an object with one required property, "foo". The "type" property specifies "foo" must be an "array", and the "description" property semantically describes it as "a list of test words". The items within "foo" must be strings.
        Thus, the object {"foo": ["bar", "baz"]} is a well-formatted instance of this example "JSON Schema". The object {"properties": {"foo": ["bar", "baz"]}}} is not well-formatted.

        Your output will be parsed and type-checked according to the provided schema instance, so make sure all fields in your output match the schema exactly and there are no trailing commas!

        Here is the JSON Schema instance your output must adhere to. Include the enclosing markdown codeblock:
        ```json
        #{schema.to_json}
        ```
      INSTRUCTIONS
    end

    # Parse the output of an LLM call extracting an object that abides by the @schema
    #
    # @param text [String] Text output from the LLM call
    # @return [Object] object that abides by the @schema
    def parse(text)
      json = text.include?("```") ? text.strip.split(/```(?:json)?/)[1] : text.strip
      parsed = JSON.parse(json)
      JSON::Validator.validate!(schema, parsed)
      parsed
    rescue => e
      raise OutputParserException.new("Failed to parse. Text: \"#{text}\". Error: #{e}", text)
    end

    private

    def validate_schema!(schema)
      errors = JSON::Validator.fully_validate_schema(schema)
      unless errors.empty?
        raise ArgumentError, "Invalid schema: \n#{errors.join("\n")}"
      end
      schema
    end
  end
end
