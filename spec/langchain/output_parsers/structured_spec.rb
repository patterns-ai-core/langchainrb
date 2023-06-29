# frozen_string_literal: true

RSpec.describe Langchain::OutputParsers::StructuredOutputParser do
  let!(:schema_example) do
    {
      type: "object",
      properties: {
        name: {
          type: "string",
          description: "Persons name"
        },
        age: {
          type: "number",
          description: "Persons age"
        },
        interests: {
          type: "array",
          items: {
            type: "object",
            properties: {
              interest: {
                type: "string",
                description: "A topic of interest"
              },
              levelOfInterest: {
                type: "number",
                description: "A value between 0 and 100 of how interested the person is in this interest"
              }
            },
            required: ["interest", "levelOfInterest"],
            additionalProperties: false
          },
          minItems: 1,
          maxItems: 3,
          description: "A list of the person's interests"
        }
      },
      required: ["name", "age", "interests"],
      additionalProperties: false
    }
  end

  let!(:json_response) do
    {
      "name" => "Hayes Weir",
      "age" => 2,
      "interests" => [
        {
          "interest" => "Dinosaurs",
          "levelOfInterest" => 90
        },
        {
          "interest" => "Sugar",
          "levelOfInterest" => 95
        }
      ]
    }
  end

  let!(:json_text_response) do
    json_response.to_json
  end

  let!(:json_with_backticks_text_response) do
    <<~RESPONSE
      I'm responding with a narrative even though you asked for only json response:

      ```json
      #{json_response.to_json}
      ```
    RESPONSE
  end

  describe "#initialize" do
    it "creates a new instance from a JSON::Schema" do
      expect(
        described_class.new(
          schema: schema_example
        )
      ).to be_a(Langchain::OutputParsers::StructuredOutputParser)
    end

    it "creates a new instance from a Hash schema" do
      expect(
        described_class.new(
          schema: schema_example
        )
      ).to be_a(Langchain::OutputParsers::StructuredOutputParser)
    end

    it "fails if input is not a valid json schema" do
      expect {
        described_class.new(
          schema: {"type" => "invalid-type"}
        )
      }.to raise_error(ArgumentError, /Invalid schema/)
    end
  end

  describe "#to_h" do
    it "returns Hash representation of structured output parser" do
      parser = described_class.from_json_schema(schema_example)
      expect(parser.to_h).to eq({
        _type: "StructuredOutputParser",
        schema: schema_example.to_json
      })
    end
  end

  describe "#get_format_instructions" do
    it "returns format instructions for the input json schema" do
      parser = described_class.from_json_schema(schema_example)
      expect(parser.get_format_instructions).to eq(
        <<~INSTRUCTIONS
          You must format your output as a JSON value that adheres to a given "JSON Schema" instance.

          "JSON Schema" is a declarative language that allows you to annotate and validate JSON documents.

          For example, the example "JSON Schema" instance {"properties": {"foo": {"description": "a list of test words", "type": "array", "items": {"type": "string"}}}, "required": ["foo"]}}
          would match an object with one required property, "foo". The "type" property specifies "foo" must be an "array", and the "description" property semantically describes it as "a list of test words". The items within "foo" must be strings.
          Thus, the object {"foo": ["bar", "baz"]} is a well-formatted instance of this example "JSON Schema". The object {"properties": {"foo": ["bar", "baz"]}}} is not well-formatted.

          Your output will be parsed and type-checked according to the provided schema instance, so make sure all fields in your output match the schema exactly and there are no trailing commas!

          Here is the JSON Schema instance your output must adhere to. Include the enclosing markdown codeblock:
          ```json
          {"type":"object","properties":{"name":{"type":"string","description":"Persons name"},"age":{"type":"number","description":"Persons age"},"interests":{"type":"array","items":{"type":"object","properties":{"interest":{"type":"string","description":"A topic of interest"},"levelOfInterest":{"type":"number","description":"A value between 0 and 100 of how interested the person is in this interest"}},"required":["interest","levelOfInterest"],"additionalProperties":false},"minItems":1,"maxItems":3,"description":"A list of the person's interests"}},"required":["name","age","interests"],"additionalProperties":false}
          ```
        INSTRUCTIONS
      )
    end
  end

  describe "#parse" do
    it "parses response text against the current @schema" do
      parser = described_class.from_json_schema(schema_example)
      expect(parser.parse(json_text_response)).to eq(json_response)
    end

    it "parses response text with markdown code backticks against the current @schema" do
      parser = described_class.from_json_schema(schema_example)
      expect(parser.parse(json_with_backticks_text_response)).to eq(json_response)
    end

    it "fails to parse response text if its borked" do
      parser = described_class.from_json_schema(schema_example)
      expect {
        parser.parse("Sorry, I'm just a large language model blah blah..")
      }.to raise_error(Langchain::OutputParsers::OutputParserException)
    end

    it "fails to parse response text if the json does not conform to the schema" do
      parser = described_class.from_json_schema(schema_example)
      expect {
        parser.parse(
          <<~RESPONSE
            {
              "name": "Elon",
              "age": 51,
              "interests": []
            }
          RESPONSE
        )
      }.to raise_error(Langchain::OutputParsers::OutputParserException, /'#\/interests' did not contain a minimum number of items/)
    end
  end

  describe ".from_json_schema" do
    it "creates a new instance from given JSON::Schema" do
      parser = described_class.from_json_schema(schema_example)
      expect(parser).to be_a(Langchain::OutputParsers::StructuredOutputParser)
      expect(parser.schema.to_json).to eq(schema_example.to_json)
    end
  end
end
