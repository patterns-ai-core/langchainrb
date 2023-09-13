# frozen_string_literal: true

require "pry-byebug"

module Langchain::Agent
  module RestGPTAgent
    class ResponseParser
      LLM_SUMMARIZE_TEMPLATE = Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/agent/restgpt_agent/prompts/llm_summarize_template.yaml")
      )
      LLM_PARSING_TEMPLATE = Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/agent/restgpt_agent/prompts/llm_parsing_template.yaml")
      )
      CODE_PARSING_SCHEMA_TEMPLATE = Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/agent/restgpt_agent/prompts/code_parsing_schema_template.yaml")
      )
      CODE_PARSING_RESPONSE_TEMPLATE = Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/agent/restgpt_agent/prompts/code_parsing_response_template.yaml")
      )
      POSTPROCESS_TEMPLATE = Langchain::Prompt.load_from_path(
        file_path: Langchain.root.join("langchain/agent/restgpt_agent/prompts/postprocess_template.yaml")
      )

      attr_reader :api_doc, :api_path, :response_schema, :response_example

      def initialize(llm:, api_path:, api_doc:, with_example: false)
        @llm = llm
        @output_key = "result"
        @return_intermediate_steps = false
        @max_json_length_1 = 500
        @max_json_length_2 = 2000
        @max_output_length = 500
        @api_doc = api_doc
        @api_path = api_path

        unless api_doc.key?("responses") && api_doc["responses"].key?("content")
          @llm_parsing_prompt = LLM_SUMMARIZE_TEMPLATE
          return
        end

        response_content = api_doc["responses"]["content"]
        @response_schema = if response_content.key?("application/json")
                            JSON.pretty_generate(response_content["application/json"]["schema"]["properties"])
                           elsif response_content.key?("application/json; charset=utf-8")
                            JSON.pretty_generate(response_content["application/json; charset=utf-8"]["schema"]["properties"])
                          end

        @encoder = Tiktoken.encoding_for_model("text-davinci-003") # Assuming Tiktoken is a module in your Ruby environment
        encoded_schema = @encoder.encode(@response_schema)
        max_schema_length = 2500
    
        @response_schema = if encoded_schema.length > max_schema_length
                            @encoder.decode(encoded_schema[0...max_schema_length]) + '...'
                          else
                            @response_schema
                          end

        @response_example = if with_example && response_content["application/json"].key?("examples")
                             JSON.pretty_generate(simplify_json(response_content["application/json"]["examples"]["response"]["value"])) # Assuming simplify_json is a method in your Ruby environment
                           else
                             "No example provided"
                           end

        @code_parsing_schema_prompt = CODE_PARSING_SCHEMA_TEMPLATE
        @code_parsing_response_prompt = CODE_PARSING_RESPONSE_TEMPLATE
        @llm_parsing_prompt = LLM_PARSING_TEMPLATE
        @postprocess_prompt = POSTPROCESS_TEMPLATE
      end

      # Placeholder for the _chain_type method
      def _chain_type
        "RestGPT Parser"
      end

      # Placeholder for the input_keys method
      def input_keys
        ["query", "json", "api_param", "response_description"]
      end

      # Placeholder for the output_keys method
      def output_keys
        if !@return_intermediate_steps
          [@output_key]
        else
          [@output_key, "intermediate_steps"]
        end
      end

      def call(query:, json:, api_param:, response_description:)
        if @code_parsing_schema_prompt.nil? || query.nil?
          prompt = @llm_parsing_prompt.format(
            api_path: api_path,
            api_description: api_doc["description"],
            query: query,
            json: json,
            api_param: api_param,
            response_description: response_description
          )

          output = @llm.complete(prompt: prompt)
          return {"result" => output}
        end

        prompt = CODE_PARSING_SCHEMA_TEMPLATE.format(
          api_path: api_path,
          api_description: api_doc["description"],
          response_schema: response_schema,
          response_example: response_example,
          query: query,
          response_description: response_description,
          api_param: api_param
        )

        code = @llm.complete(prompt: prompt)

        Langchain.logger.info("Code: \n#{code}") # Logging in Ruby, it can be implemented as per the Ruby logging standards

        # TODO: Fix this
        json_data = JSON.parse(json)

        # repl = Langchain::Tool::RubyCodeInterpreter.new(globals: {"data" => json_data})

        # res = repl.execute(code)
        # output = res

        output = Langchain::Tool::RubyREPL.new.run("data = #{json_data}; #{code}")

        if output.nil? || output.empty?

          json_data = JSON.parse(json)
          encoded_json = @encoder.encode(json)
          if encoded_json.length > @max_json_length_1
            simplified_json_data = @encoder.decode(encoded_json[0..@max_json_length_1]) + '...'
          else
            simplified_json_data = json
          end

          prompt = @code_parsing_response_prompt.format(
            api_path: api_path,
            api_description: api_doc["description"],
            response_schema: response_schema,
            query: query,
            json: simplified_json_data,
            api_param: api_param
          )

          code = @llm.complete(prompt: prompt)

          output = Langchain::Tool::RubyREPL.new.run("data = #{json_data}; #{code}")

          # repl = RubyREPL.new(globals: {"data" => json_data})
          # res = repl.execute(code)
          # output = res
        end

        if output.nil? || output.empty?
          if encoded_json.length > @max_json_length_2
            simplified_json_data = @encoder.decode(encoded_json[0..@max_json_length_2]) + '...'
          end

          prompt = LLM_PARSING_TEMPLATE.format(
            api_path: api_path,
            api_description: api_doc["description"],
            query: query,
            json: simplified_json_data,
            api_param: api_param,
            response_description: response_description
          )

          output = @llm.complete(prompt: prompt)
        end

        encoded_output = @encoder.encode(output)
        if encoded_output.length > @max_output_length
          output = @encoder.decode(encoded_output[0..@max_output_length])

          Langchain.logger.info("Output too long, truncating to #{@max_output_length} tokens") # Uncomment and adapt to your Ruby logging setup

          prompt = POSTPROCESS_TEMPLATE.format(
            truncated_str: output
          )

          output = @llm.complete(prompt: prompt)
        end

        return {"result" => output}
      end
    end
  end
end
