# frozen_string_literal: true

module Langchain::Agent
  module RestGPTAgent
    class SimpleResponseParser
      attr_accessor :llm, :llm_parsing_prompt, :encoder, :max_json_length, :output_key, :return_intermediate_steps

      LLM_SUMMARIZE_TEMPLATE = Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/agent/restgpt_agent/prompts/llm_summarize_template.yaml")
      )

      LLM_PARSING_TEMPLATE = Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/agent/restgpt_agent/prompts/llm_parsing_template.yaml")
      )

      def initialize(llm:, api_path:, api_doc:, with_example: false)
        @llm_parsing_prompt = if !api_doc.key?("responses") || !api_doc["responses"].key?("content")
          LLM_SUMMARIZE_TEMPLATE
        else
          LLM_PARSING_TEMPLATE
        end

        @encoder = Tiktoken.encoding_for_model("text-davinci-003")

        @llm = llm
        @max_json_length = 1000
        @output_key = "result"
        @return_intermediate_steps = false
      end

      def call(inputs)
        if inputs["query"].nil?

          prompt = @llm_parsing_prompt.format(
            api_path: api_path,
            api_description: api_doc["description"],
            query: input["query"],
            json: inputs["json"], 
            api_param: inputs["api_param"],
            response_description: inputs["response_description"]
          )

          output = @llm.complete(prompt: prompt)

          return {"result" => output}
        end

        encoded_json = @encoder.encode(inputs["json"])
        if encoded_json.length > @max_json_length
          encoded_json = @encoder.decode(encoded_json[0, @max_json_length]) + '...'
        end

        prompt = @llm_parsing_prompt.format(
          api_path: api_path,
          api_description: api_doc["description"],
          query: input["query"],
          json: inputs["json"], 
          api_param: inputs["api_param"],
          response_description: inputs["response_description"]
        )

        output = @llm.complete(prompt: prompt)

        {"result" => output}
      end
    end
  end
end
