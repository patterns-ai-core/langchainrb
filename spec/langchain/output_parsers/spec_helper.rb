# frozen_string_literal: true

# spec_helper.rb

def schema_example
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
