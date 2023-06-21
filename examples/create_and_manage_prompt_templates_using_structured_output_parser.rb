require "langchain"

# Generate a prompt that directs the LLM to provide a JSON response that adheres to a specific JSON schema.
json_schema = {
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
parser = Langchain::OutputParsers::StructuredOutputParser.from_json_schema(json_schema)
prompt = Langchain::Prompt::PromptTemplate.new(template: "Generate details of a fictional character.\n{format_instructions}\nCharacter description: {description}", input_variables: ["description", "format_instructions"])
prompt.format(description: "Korean chemistry student", format_instructions: parser.get_format_instructions)
# Generate details of a fictional character.
# You must format your output as a JSON value that adheres to a given "JSON Schema" instance.

# "JSON Schema" is a declarative language that allows you to annotate and validate JSON documents.

# For example, the example "JSON Schema" instance {"properties": {"foo": {"description": "a list of test words", "type": "array", "items": {"type": "string"}}, "required": ["foo"]}
# would match an object with one required property, "foo". The "type" property specifies "foo" must be an "array", and the "description" property semantically describes it as "a list of test words". The items within "foo" must be strings.
# Thus, the object {"foo": ["bar", "baz"]} is a well-formatted instance of this example "JSON Schema". The object {"properties": {"foo": ["bar", "baz"]}} is not well-formatted.

# Your output will be parsed and type-checked according to the provided schema instance, so make sure all fields in your output match the schema exactly and there are no trailing commas!

# Here is the JSON Schema instance your output must adhere to. Include the enclosing markdown codeblock:
# ```json
# {"type":"object","properties":{"name":{"type":"string","description":"Persons name"},"age":{"type":"number","description":"Persons age"},"interests":{"type":"array","items":{"type":"object","properties":{"interest":{"type":"string","description":"A topic of interest"},"levelOfInterest":{"type":"number","description":"A value between 0 and 100 of how interested the person is in this interest"},"required":["interest","levelOfInterest"],"additionalProperties":false},"minItems":1,"maxItems":3,"description":"A list of the person's interests"},"required":["name","age","interests"],"additionalProperties":false}
# ```

# Character description: 2 year old hobbit

# LLM example response:
llm_example_response = <<~RESPONSE
  Here is your character:
  ```json
  {
    "name": "Kim Ji-hyun",
    "age": 22,
    "interests": [
      {
        "interest": "Organic Chemistry",
        "levelOfInterest": 85
      },
      {
        "interest": "Biochemistry",
        "levelOfInterest": 70
      },
      {
        "interest": "Analytical Chemistry",
        "levelOfInterest": 60
      }
    ]
  }
  ```
RESPONSE

parser.parse(llm_example_response)
# {
#   "name" => "Kim Ji-hyun",
#   "age" => 22,
#   "interests" => [
#     {
#       "interest" => "Organic Chemistry",
#       "levelOfInterest" => 85
#     },
#     {
#       "interest" => "Biochemistry",
#       "levelOfInterest" => 70
#     },
#     {
#       "interest" => "Analytical Chemistry",
#       "levelOfInterest" => 60
#     }
#   ]
# }
